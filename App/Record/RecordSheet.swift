import MemoKit
import SwiftUI

struct RecordSheet: View {
    let mode: SheetMode
    @Environment(Recorder.self) private var recorder
    @Environment(Session.self) private var session
    @State private var detent: PresentationDetent

    init(mode: SheetMode) {
        self.mode = mode
        _detent = State(initialValue: mode == .recorder ? .height(Metrics.compactSheet) : .large)
    }

    private var detents: Set<PresentationDetent> {
        mode == .recorder ? [.height(Metrics.compactSheet), .large] : [.large]
    }

    var body: some View {
        GeometryReader { proxy in
            let expansion = mode == .recorder ? min(1, max(0, (proxy.size.height - Metrics.compactSheet) / 200)) : 1
            ZStack {
                if mode == .recorder, expansion < 1 {
                    CompactRecorder { stop() }
                        .opacity(1 - min(1, expansion * 2.5))
                }
                if expansion > 0 {
                    FullRecorder(mode: mode) { finish() }
                        .opacity(min(1, max(0, expansion * 1.6 - 0.4)))
                }
            }
        }
        .presentationDetents(detents, selection: $detent)
        .onDisappear {
            session.options = nil
            session.transcript = nil
            session.editing = nil
        }
        .onAppear {
            if let requested = session.detent {
                detent = requested
                session.detent = nil
            }
        }
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.disabled)
        .interactiveDismissDisabled(recorder.phase != .idle)
        .presentationSizing(.page)
    }

    private func stop() {
        let recording = recorder.stop()
        session.sheet = nil
        session.expanded = recording?.id
    }

    private func finish() {
        if mode == .recorder {
            stop()
        } else {
            recorder.stop()
            session.sheet = nil
        }
    }
}

struct CompactRecorder: View {
    let stop: () -> Void
    @Environment(Recorder.self) private var recorder

    var body: some View {
        VStack(spacing: 0) {
            Text(recorder.take?.title ?? "")
                .font(.subheadline.weight(.semibold))
                .padding(.top, 26)
            TimelineView(.animation(paused: recorder.phase != .recording)) { context in
                let now = recorder.displaySeconds()
                VStack(spacing: 0) {
                    Text(Format.timer(now))
                        .font(.footnote)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .padding(.top, 3)
                    LiveStrip(levels: recorder.levels, seconds: now)
                        .frame(height: 64)
                        .padding(.top, 22)
                }
            }
            Spacer(minLength: 0)
            Button(action: stop) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.record)
                    .frame(width: 24, height: 24)
                    .frame(width: 60, height: 60)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
            .accessibilityLabel("Stop")
            .padding(.bottom, 22)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LiveStrip: View {
    let levels: [Float]
    let seconds: TimeInterval

    var body: some View {
        GeometryReader { proxy in
            let window = Double(proxy.size.width / 60)
            WaveformBars(
                peaks: levels,
                duration: seconds,
                visible: (seconds - window)...seconds,
                playhead: seconds,
                played: .record,
                unplayed: .clear,
                barWidth: 2,
                spacing: 2
            )
            .background {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: proxy.size.height / 2))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height / 2))
                }
                .stroke(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [1, 3]))
            }
        }
        .padding(.horizontal, 16)
        .accessibilityLabel("Waveform")
    }
}
