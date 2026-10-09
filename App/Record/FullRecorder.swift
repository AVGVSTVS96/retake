import MemoKit
import SwiftUI

struct FullRecorder: View {
    let mode: SheetMode
    let done: () -> Void
    @Environment(Recorder.self) private var recorder
    @Environment(Library.self) private var library
    @Environment(Player.self) private var player
    @Environment(Session.self) private var session

    private var recording: Recording? {
        if case let .recording(id) = mode { return library.recording(id) }
        return nil
    }

    private var isReplacing: Bool { recorder.phase != .idle && recorder.replacing != nil && recorder.replacing?.id == recording?.id }
    private var isRecording: Bool { (mode == .recorder && recorder.phase != .idle) || isReplacing }

    private func capture(at time: TimeInterval) -> (peaks: [Float], duration: TimeInterval, time: TimeInterval) {
        guard let replacing = recorder.replacing, let recording else {
            return (recorder.levels, time, time)
        }
        let original = library.peaks[recording.id] ?? []
        let start = Int(replacing.at * Peaks.binsPerSecond)
        let end = start + recorder.levels.count
        let merged = Array(original.prefix(start)) + recorder.levels + Array(original.dropFirst(min(original.count, end)))
        return (merged, max(recording.duration, replacing.at + time), replacing.at + time)
    }

    private var showsOptions: Bool { recording != nil && session.options == recording?.id }
    private var showsTranscript: Bool { session.transcript != nil && session.transcript == (recording?.id ?? recorder.take?.id) }

    var body: some View {
        ZStack {
            if showsOptions, let recording {
                OptionsPanel(recording: recording) { session.options = nil }
                    .transition(.blurReplace)
            } else if let recording, session.editing == recording.id {
                EditView(recording: recording)
                    .transition(.blurReplace)
            } else {
                recorderBody
                    .transition(.blurReplace)
            }
        }
        .animation(.smooth(duration: 0.25), value: showsOptions)
        .animation(.smooth(duration: 0.25), value: session.editing)
        .onAppear {
            if let recording {
                player.load(recording, url: library.url(for: recording), peaks: library.peaks[recording.id] ?? [])
            }
        }
    }

    private var recorderBody: some View {
        VStack(spacing: 0) {
            header
            TimelineView(.animation(paused: !(recorder.phase == .recording || player.isPlaying))) { _ in
                let live = capture(at: recorder.displaySeconds())
                let time = isRecording ? live.time : player.time()
                VStack(spacing: 0) {
                    ZStack {
                        if showsTranscript {
                            TranscriptView(
                                transcript: isRecording ? recorder.live?.transcript : recording?.transcript,
                                time: time,
                                isPending: recording.map { library.transcribing.contains($0.id) } ?? (recorder.live?.isAvailable ?? false)
                            )
                                .transition(.opacity)
                        } else {
                            WaveformPanel(
                                peaks: isRecording ? live.peaks : library.peaks[recording?.id ?? UUID()] ?? [],
                                duration: isRecording ? live.duration : (recording?.duration ?? 0),
                                time: time,
                                style: recorder.phase == .recording && isRecording ? .recording : .playback,
                                replaced: isReplacing ? recorder.replacing.map { $0.at..<live.time } : nil,
                                onSeek: isRecording ? nil : { player.seek(to: $0) }
                            )
                            .transition(.opacity)
                        }
                    }
                    .frame(minHeight: 180, idealHeight: 372, maxHeight: 372)
                    .animation(.smooth(duration: 0.25), value: showsTranscript)
                    .padding(.top, 22)
                    Text(Format.timer(time))
                        .font(.system(size: 34, weight: .semibold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .padding(.top, 28)
                }
            }
            Transport(size: .sheet, isEnabled: !isRecording)
                .padding(.top, 22)
            Spacer(minLength: 16)
            bottomBar
        }
    }

    private var header: some View {
        VStack(spacing: 2) {
            HStack {
                if let recording {
                    RecordingMenu(recording: recording, style: .sheet)
                        .glassEffect(.regular.interactive(), in: .circle)
                } else {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular, in: .circle)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: done) {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Done")
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            Group {
                if let recording {
                    TitleField(recording: recording)
                } else {
                    Text(recorder.take?.title ?? "").lineLimit(1)
                }
            }
            .font(.headline)
            .padding(.horizontal, 60)
            .padding(.top, 4)
            HStack(spacing: 6) {
                Text(Format.headerDate(recording?.created ?? recorder.take?.created ?? .now))
                Text(Format.duration(recording?.duration ?? recorder.seconds))
                    .monospacedDigit()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
        }
    }

    private var bottomBar: some View {
        HStack {
            Button {
                session.transcript = showsTranscript ? nil : (recording?.id ?? recorder.take?.id)
            } label: {
                Image(systemName: showsTranscript ? "quote.bubble.fill" : "quote.bubble")
                    .foregroundStyle(showsTranscript ? Color.white : Color.primary)
                    .frame(width: 44, height: 44)
                    .background(showsTranscript ? Color.accentColor : .clear, in: .circle)
            }
            .glassEffect(.regular.interactive(), in: .circle)
            .accessibilityLabel("Transcription")
            Spacer()
            centerButton
            Spacer()
            Button {
                session.options = recording?.id
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .frame(width: 44, height: 44)
            }
            .glassEffect(.regular.interactive(), in: .circle)
            .disabled(recording == nil)
            .accessibilityLabel("Playback Options")
        }
        .buttonStyle(.plain)
        .tint(.primary)
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
    }

    @ViewBuilder
    private var centerButton: some View {
        if mode == .recorder || isReplacing {
            Button {
                recorder.phase == .recording ? recorder.pause() : recorder.resume()
            } label: {
                Group {
                    if recorder.phase == .paused {
                        Text("RESUME")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.record)
                    } else {
                        Image(systemName: "pause.fill")
                            .font(.title2)
                            .foregroundStyle(Color.record)
                    }
                }
                .contentTransition(.opacity)
                .frame(width: 140, height: 56)
            }
            .glassEffect(.regular.interactive(), in: .capsule)
            .accessibilityLabel(recorder.phase == .paused ? "Resume" : "Pause")
        } else {
            Button {
                guard let recording else { return }
                let time = player.time()
                player.pause()
                Task { await recorder.record(replacing: recording.id, at: time) }
            } label: {
                Text("REPLACE")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 140, height: 44)
            }
            .glassEffect(.regular.tint(.record).interactive(), in: .capsule)
            .disabled(recorder.phase != .idle || showsTranscript)
            .opacity(showsTranscript ? 0.4 : 1)
        }
    }
}

struct WaveformPanel: View {
    enum Style {
        case recording, playback, editing
    }

    let peaks: [Float]
    let duration: TimeInterval
    let time: TimeInterval
    let style: Style
    var selection: ClosedRange<TimeInterval>?
    var replaced: Range<TimeInterval>?
    var onSeek: ((TimeInterval) -> Void)?
    @State private var scrub: (start: TimeInterval, time: TimeInterval)?
    static let pointsPerSecond: CGFloat = 92

    var body: some View {
        GeometryReader { proxy in
            let shown = scrub?.time ?? time
            let half = Double(proxy.size.width / 2 / Self.pointsPerSecond)
            let visible = (shown - half)...(shown + half)
            let tint = switch style {
            case .recording: Color.record
            case .playback: Color.accentColor
            case .editing: Color.yellow
            }
            let isLive = peaks.count > 0 && duration <= shown + 0.05
            VStack(spacing: 0) {
                ZStack {
                    Rectangle().fill(Color.panel)
                    if let selection {
                        Canvas { context, size in
                            let x = { (t: TimeInterval) in (t - visible.lowerBound) / (visible.upperBound - visible.lowerBound) * size.width }
                            let rect = CGRect(x: x(selection.lowerBound), y: 0, width: x(selection.upperBound) - x(selection.lowerBound), height: size.height)
                            context.fill(Path(rect), with: .color(.yellow.opacity(0.25)))
                        }
                    }
                    if style == .recording || isLive {
                        Path { path in
                            path.move(to: CGPoint(x: proxy.size.width / 2, y: 0))
                            path.addLine(to: CGPoint(x: proxy.size.width, y: 0))
                        }
                        .stroke(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [1, 3]))
                        .offset(y: (proxy.size.height - 28) / 2)
                    }
                    WaveformBars(
                        peaks: peaks,
                        duration: duration,
                        visible: visible,
                        playhead: shown,
                        played: style == .recording ? .record : Color(.tertiaryLabel),
                        unplayed: Color(.label),
                        barWidth: 2,
                        spacing: 2,
                        hidesFuture: style == .recording && replaced == nil,
                        highlight: replaced.map { ($0, Color.record) }
                    )
                    .padding(.vertical, 56)
                    Playhead(tint: tint)
                }
                Ruler(visible: visible)
                    .frame(height: 28)
            }
            .contentShape(.rect)
            .gesture(drag, isEnabled: onSeek != nil)
        }
        .frame(minHeight: 180, idealHeight: 372, maxHeight: 372)
        .accessibilityLabel("Waveform")
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let start = scrub?.start ?? time
                let target = start - Double(value.translation.width / Self.pointsPerSecond)
                scrub = (start, min(duration, max(0, target)))
            }
            .onEnded { value in
                let start = scrub?.start ?? time
                let target = min(duration, max(0, start - Double(value.predictedEndTranslation.width / Self.pointsPerSecond)))
                onSeek?(target)
                scrub = nil
            }
    }
}

struct Playhead: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let x = proxy.size.width / 2
            ZStack {
                Rectangle().fill(tint).frame(width: 1.5)
                Circle().fill(tint).frame(width: 8, height: 8).position(x: x, y: 0)
                Circle().fill(tint).frame(width: 8, height: 8).position(x: x, y: proxy.size.height)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
    }
}

struct Ruler: View {
    let visible: ClosedRange<TimeInterval>

    var body: some View {
        Canvas { context, size in
            let span = visible.upperBound - visible.lowerBound
            guard span > 0 else { return }
            let perSecond = size.width / span
            var tick = (visible.lowerBound * 4).rounded(.down) / 4
            while tick <= visible.upperBound {
                let x = (tick - visible.lowerBound) * perSecond
                let isSecond = tick == tick.rounded()
                if tick >= 0 {
                    let height: CGFloat = isSecond ? 8 : 4
                    context.fill(Path(CGRect(x: x, y: 0, width: 1, height: height)), with: .color(Color(.tertiaryLabel)))
                    if isSecond {
                        context.draw(
                            Text(Format.ruler(tick)).font(.system(size: 11)).monospacedDigit().foregroundStyle(Color(.tertiaryLabel)),
                            at: CGPoint(x: x, y: 18)
                        )
                    }
                }
                tick += 0.25
            }
        }
    }
}

struct TitleField: View {
    let recording: Recording
    @Environment(Library.self) private var library
    @State private var title = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Name", text: $title)
            .multilineTextAlignment(.center)
            .submitLabel(.done)
            .focused($isFocused)
            .onAppear { title = recording.title }
            .onChange(of: isFocused) { _, focused in
                if !focused { commit() }
            }
            .onSubmit(commit)
            .accessibilityLabel("Edit Title")
    }

    private func commit() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            title = recording.title
            return
        }
        library.update(recording.id) { $0.title = trimmed }
    }
}
