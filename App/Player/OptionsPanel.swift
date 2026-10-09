import MemoKit
import SwiftUI

struct OptionsPanel: View {
    let recording: Recording
    let done: () -> Void
    @Environment(Library.self) private var library
    @Environment(Player.self) private var player

    private var options: Binding<PlaybackOptions> {
        Binding {
            library.recording(recording.id)?.playback ?? PlaybackOptions()
        } set: { options in
            library.update(recording.id) { $0.playback = options }
            if player.current == recording.id { player.setOptions(options) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button { options.wrappedValue = PlaybackOptions() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .frame(width: 44, height: 44)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                .disabled(options.wrappedValue.isDefault)
                .accessibilityLabel("Reset playback options")
                Spacer()
                Text("Options").font(.headline)
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
            .buttonStyle(.plain)
            .padding(.top, 14)
            Text("Playback Speed")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, 18)
                .padding(.leading, 16)
            SpeedSlider(speed: options.speed)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color.panel, in: .rect(cornerRadius: 22, style: .continuous))
                .padding(.top, 8)
            VStack(spacing: 0) {
                Toggle("Skip Silence", isOn: options.skipSilence)
                    .padding(.vertical, 14)
                Divider()
                Toggle("Enhance Recording", isOn: options.enhance)
                    .padding(.vertical, 14)
            }
            .padding(.horizontal, 16)
            .background(Color.panel, in: .rect(cornerRadius: 22, style: .continuous))
            .padding(.top, 16)
            Spacer()
        }
        .padding(.horizontal, 16)
        .background(Color(.systemGroupedBackground).opacity(0.001))
    }
}

struct SpeedSlider: View {
    @Binding var speed: Double
    static let stops: [Double] = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tortoise")
                .foregroundStyle(.secondary)
            GeometryReader { proxy in
                let width = proxy.size.width
                let index = Double(Self.stops.firstIndex { $0 >= speed - 0.001 } ?? 2)
                let step = width / Double(Self.stops.count - 1)
                let x = index * step
                let center = 2 * step
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemFill)).frame(height: 4)
                    ForEach(Self.stops.indices, id: \.self) { stop in
                        Circle().fill(Color(.tertiaryLabel)).frame(width: 3, height: 3)
                            .offset(x: Double(stop) * step - 1.5, y: 9)
                    }
                    Capsule().fill(Color.accentColor)
                        .frame(width: abs(x - center), height: 4)
                        .offset(x: min(x, center))
                    Capsule()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                        .frame(width: 38, height: 24)
                        .offset(x: x - 19)
                }
                .frame(maxHeight: .infinity)
                .contentShape(.rect)
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    let snapped = Int((value.location.x / step).rounded())
                    let next = Self.stops[min(Self.stops.count - 1, max(0, snapped))]
                    if next != speed {
                        speed = next
                    }
                })
                .sensoryFeedback(.selection, trigger: speed)
                .animation(.spring(duration: 0.25, bounce: 0.2), value: speed)
            }
            Image(systemName: "hare")
                .foregroundStyle(.secondary)
        }
        .accessibilityElement()
        .accessibilityLabel("Playback Speed")
        .accessibilityValue("\(speed.formatted())×")
        .accessibilityAdjustableAction { direction in
            let index = Self.stops.firstIndex { $0 >= speed - 0.001 } ?? 2
            let next = direction == .increment ? min(index + 1, Self.stops.count - 1) : max(index - 1, 0)
            speed = Self.stops[next]
        }
    }
}

struct TranscriptView: View {
    let transcript: Transcript?
    let time: TimeInterval
    var isPending = false

    var body: some View {
        ScrollView {
            if let transcript, !transcript.segments.isEmpty {
                let current = transcript.segmentIndex(at: time)
                transcript.segments.indices.reduce(Text("")) { text, index in
                    let segment = transcript.segments[index]
                    let word = Text(segment.text + " ")
                    return Text("\(text)\(index == current ? word.foregroundStyle(.primary).fontWeight(.semibold) : word.foregroundStyle(.secondary))")
                }
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(.horizontal, 20)
            } else {
                Text(isPending ? "Transcription in progress…" : "Couldn’t Transcribe Audio")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 300)
            }
        }
        .scrollIndicators(.hidden)
    }
}
