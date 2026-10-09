import MemoKit
import SwiftUI

struct SplitRoot: View {
    @Environment(Session.self) private var session
    @Environment(Recorder.self) private var recorder
    @Environment(Library.self) private var library
    @State private var scope: Scope? = .all
    @State private var columns = NavigationSplitViewVisibility.doubleColumn

    var body: some View {
        @Bindable var session = session
        NavigationSplitView(columnVisibility: $columns) {
            FoldersView(selection: $scope)
                .listStyle(.sidebar)
        } content: {
            RecordingsList(scope: scope ?? .all, isSplit: true)
                .id(scope)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } detail: {
            DetailPane()
                .searchable(text: $session.query, placement: .toolbar, prompt: Text(library.recordings.contains { $0.transcript != nil } ? "Titles, Transcripts" : "Search"))
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(item: Binding(get: { if case .recording = session.sheet { session.sheet } else { nil } }, set: { session.sheet = $0 })) { mode in
            RecordSheet(mode: mode)
        }
        .task {
            if session.selected == nil { session.selected = library.recordings(in: .all).first?.id }
            await Demo.stage(session: session, recorder: recorder, library: library)
        }
    }
}

struct DetailPane: View {
    @Environment(Session.self) private var session
    @Environment(Recorder.self) private var recorder
    @Environment(Library.self) private var library
    @Environment(Player.self) private var player

    var body: some View {
        Group {
            if recorder.phase != .idle || session.sheet == .recorder {
                FullRecorder(mode: .recorder) {
                    let recording = recorder.stop()
                    session.sheet = nil
                    session.selected = recording?.id ?? session.selected
                }
            } else if let id = session.selected, let recording = library.recording(id) {
                PlayerDetail(recording: recording)
                    .id(id)
            } else {
                ContentUnavailableView("No Recording Selected", systemImage: "waveform", description: Text("Tap the Record button to start a Voice Memo"))
            }
        }
        .animation(.smooth(duration: 0.3), value: recorder.phase == .idle)
    }
}

struct PlayerDetail: View {
    let recording: Recording
    @Environment(Session.self) private var session
    @Environment(Library.self) private var library
    @Environment(Player.self) private var player

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 2) {
                Text(recording.title)
                    .font(.title3.weight(.semibold))
                HStack(spacing: 6) {
                    Text(Format.headerDate(recording.created))
                    Text(Format.duration(recording.duration)).monospacedDigit()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            }
            .padding(.top, 12)
            .layoutPriority(1)
            TimelineView(.animation(paused: !player.isPlaying)) { _ in
                let time = player.current == recording.id ? player.time() : 0
                VStack(spacing: 0) {
                    Group {
                        if session.transcript == recording.id {
                            TranscriptView(transcript: recording.transcript, time: time, isPending: library.transcribing.contains(recording.id))
                                .frame(minHeight: 180, idealHeight: 372, maxHeight: 372)
                        } else {
                            WaveformPanel(peaks: library.peaks[recording.id] ?? [], duration: recording.duration, time: time, style: .playback) { player.seek(to: $0) }
                        }
                    }
                    .padding(.top, 28)
                    Overview(peaks: library.peaks[recording.id] ?? [], duration: recording.duration, time: time) { player.seek(to: $0) }
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                    Text(Format.timer(time))
                        .font(.system(size: 34, weight: .semibold))
                        .monospacedDigit()
                        .padding(.top, 22)
                }
            }
            Spacer(minLength: 16)
            Transport(size: .bar)
                .padding(.horizontal, 26)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .capsule)
                .padding(.bottom, 24)
        }
        .onAppear { player.load(recording, url: library.url(for: recording), peaks: library.peaks[recording.id] ?? []) }
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                ShareLink(item: library.url(for: recording), preview: SharePreview(recording.title)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                Button(recording.isFavorite ? "Unfavorite" : "Favorite", systemImage: recording.isFavorite ? "heart.fill" : "heart") {
                    library.update(recording.id) { $0.isFavorite.toggle() }
                }
                Menu("Move to Folder", systemImage: "folder") {
                    Button("All Recordings") { library.move([recording.id], to: nil) }
                    ForEach(library.folders) { folder in
                        Button(folder.name) { library.move([recording.id], to: folder.id) }
                    }
                }
                Button("Delete", systemImage: "trash") {
                    player.unload()
                    let next = library.recordings(in: .all).first { $0.id != recording.id }?.id
                    library.trash([recording.id])
                    session.selected = next
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Playback Options", systemImage: "slider.horizontal.3") { session.options = recording.id }
                    .popover(isPresented: Binding(get: { session.options == recording.id && session.sheet == nil }, set: { if !$0 { session.options = nil } })) {
                        OptionsPanel(recording: recording) { session.options = nil }
                            .frame(width: 380, height: 330)
                            .presentationCompactAdaptation(.popover)
                    }
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                Button("Transcription", systemImage: session.transcript == recording.id ? "quote.bubble.fill" : "quote.bubble") {
                    session.transcript = session.transcript == recording.id ? nil : recording.id
                }
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit Recording", systemImage: "waveform") { session.sheet = .recording(recording.id) }
            }
        }
    }
}

struct Overview: View {
    let peaks: [Float]
    let duration: TimeInterval
    let time: TimeInterval
    let onSeek: (TimeInterval) -> Void

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.panel)
                    WaveformBars(peaks: peaks, duration: duration, visible: 0...max(duration, 0.01), playhead: 0, played: Color(.secondaryLabel), unplayed: Color(.secondaryLabel), barWidth: 1.5, spacing: 1.5)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 4)
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: 4)
                        .offset(x: duration > 0 ? (proxy.size.width - 4) * time / duration : 0)
                }
                .contentShape(.rect)
                .gesture(DragGesture(minimumDistance: 0).onChanged { onSeek(duration * min(1, max(0, $0.location.x / proxy.size.width))) })
            }
            .frame(height: 36)
            HStack {
                Text(Format.duration(0))
                Spacer()
                Text(Format.duration(duration))
            }
            .font(.caption2)
            .monospacedDigit()
            .foregroundStyle(.secondary)
        }
    }
}
