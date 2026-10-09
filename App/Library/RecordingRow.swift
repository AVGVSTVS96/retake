import MemoKit
import SwiftUI

struct RecordingRow: View {
    let recording: Recording
    let scope: Scope
    let isExpanded: Bool
    @Environment(Library.self) private var library
    @Environment(Session.self) private var session
    @Environment(Player.self) private var player
    @Environment(\.isSelectedRow) private var isSelected

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(recording.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if isExpanded {
                    RecordingMenu(recording: recording)
                        .transition(.opacity)
                }
            }
            HStack(spacing: 6) {
                Text(Format.listDate(recording.created))
                if recording.transcript != nil {
                    Image(systemName: "quote.bubble")
                        .imageScale(.small)
                        .accessibilityLabel("Transcription available")
                }
                Spacer()
                if !isExpanded {
                    Text(Format.duration(recording.duration))
                        .monospacedDigit()
                }
            }
            .font(.subheadline)
            .foregroundStyle(isSelected ? AnyShapeStyle(.white.opacity(0.85)) : AnyShapeStyle(.secondary))
            .padding(.top, 2)
            if isExpanded {
                InlinePlayer(recording: recording)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 11)
        .foregroundStyle(isSelected ? .white : .primary)
        .clipped()
    }
}

extension EnvironmentValues {
    @Entry var isSelectedRow = false
}

struct InlinePlayer: View {
    let recording: Recording
    @Environment(Library.self) private var library
    @Environment(Session.self) private var session
    @Environment(Player.self) private var player

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.animation(paused: !player.isPlaying)) { _ in
                let time = player.current == recording.id ? player.time() : 0
                VStack(spacing: 6) {
                    Scrubber(value: time, total: recording.duration) { player.seek(to: $0) }
                    HStack {
                        Text(Format.duration(time))
                        Spacer()
                        Text(Format.remaining(recording.duration - time))
                    }
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 14)
            HStack {
                Button {
                    session.sheet = .recording(recording.id)
                } label: {
                    Image(systemName: "waveform")
                        .font(.title3)
                }
                .tint(.accentColor)
                .accessibilityLabel("Edit Recording")
                Spacer()
                Transport(size: .row)
                Spacer()
                Button {
                    player.unload()
                    session.expanded = nil
                    library.trash([recording.id])
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                }
                .tint(.accentColor)
                .accessibilityLabel("Delete")
            }
            .buttonStyle(.borderless)
            .padding(.top, 10)
        }
    }
}

struct Scrubber: View {
    let value: TimeInterval
    let total: TimeInterval
    let onSeek: (TimeInterval) -> Void
    @State private var dragging: TimeInterval?

    var body: some View {
        GeometryReader { proxy in
            let shown = dragging ?? value
            let fraction = total > 0 ? min(1, max(0, shown / total)) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.systemFill))
                Capsule().fill(Color.primary).frame(width: proxy.size.width * fraction)
            }
            .frame(height: dragging == nil ? 4 : 6)
            .frame(maxHeight: .infinity)
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { dragging = total * min(1, max(0, $0.location.x / proxy.size.width)) }
                    .onEnded { _ in
                        if let dragging { onSeek(dragging) }
                        dragging = nil
                    }
            )
            .animation(.spring(duration: 0.25), value: dragging == nil)
        }
        .frame(height: 16)
        .accessibilityElement()
        .accessibilityLabel("Track Position")
        .accessibilityValue(Format.duration(value))
    }
}

struct Transport: View {
    enum Size {
        case row, sheet, bar

        var skip: Font {
            switch self {
            case .row: .title3
            case .sheet, .bar: .title2
            }
        }

        var play: CGFloat {
            switch self {
            case .row: 28
            case .sheet: 34
            case .bar: 28
            }
        }

        var spacing: CGFloat {
            switch self {
            case .row: 28
            case .sheet: 44
            case .bar: 32
            }
        }
    }

    let size: Size
    var isEnabled = true
    @Environment(Player.self) private var player

    var body: some View {
        HStack(spacing: size.spacing) {
            Button { player.skip(by: -15) } label: {
                Image(systemName: "gobackward.15").font(size.skip)
            }
            .accessibilityLabel("Rewind, 15 seconds")
            Button { player.toggle() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: size.play))
                    .frame(width: size.play + 8, height: size.play + 8)
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            Button { player.skip(by: 15) } label: {
                Image(systemName: "goforward.15").font(size.skip)
            }
            .accessibilityLabel("Skip forward, 15 seconds")
        }
        .tint(.primary)
        .buttonStyle(.borderless)
        .disabled(!isEnabled)
    }
}
