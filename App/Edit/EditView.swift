import MemoKit
import SwiftUI

struct EditView: View {
    let recording: Recording
    @Environment(Library.self) private var library
    @Environment(Player.self) private var player
    @Environment(Session.self) private var session
    @State private var draft: EditDraft?
    @State private var selection: ClosedRange<TimeInterval> = 0...0
    @State private var isConfirming = false
    @State private var failed = false

    var body: some View {
        VStack(spacing: 0) {
            header
            if let draft {
                TimelineView(.animation(paused: !player.isPlaying)) { _ in
                    let time = player.time()
                    VStack(spacing: 0) {
                        WaveformPanel(peaks: draft.peaks, duration: draft.duration, time: time, style: .editing, selection: selection) { player.seek(to: $0) }
                            .frame(minHeight: 180, idealHeight: 372, maxHeight: 372)
                            .padding(.top, 22)
                        TrimStrip(peaks: draft.peaks, duration: draft.duration, time: time, selection: $selection)
                            .padding(.horizontal, 40)
                            .padding(.top, 24)
                        Text(Format.timer(time))
                            .font(.system(size: 34, weight: .semibold))
                            .monospacedDigit()
                            .padding(.top, 24)
                    }
                }
                Transport(size: .sheet)
                    .padding(.top, 22)
            }
            Spacer(minLength: 16)
            HStack {
                Button("Trim", systemImage: "arrow.right.and.line.vertical.and.arrow.left") { apply(keeping: [selection.lowerBound..<selection.upperBound]) }
                    .labelStyle(.iconOnly)
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .disabled(!isPartial)
                Spacer()
                Button("Delete", systemImage: "trash", role: .destructive) {
                    guard let draft else { return }
                    apply(keeping: [0..<selection.lowerBound, selection.upperBound..<draft.duration].filter { $0.upperBound - $0.lowerBound > 0.01 })
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(Color.record)
                .frame(width: 52, height: 52)
                .glassEffect(.regular.interactive(), in: .circle)
                .disabled(!isPartial)
            }
            .font(.title3)
            .buttonStyle(.plain)
            .padding(.horizontal, 28)
            .padding(.bottom, 18)
        }
        .onAppear { load(library.draft(of: recording.id)) }
        .confirmationDialog("Save Voice Memo", isPresented: $isConfirming) {
            Button("Save Recording") { save(asNew: false) }
            Button("Save as New Recording") { save(asNew: true) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Save current recording, or save as a new recording to include only the trimmed section")
        }
        .alert("Unable to Create Voice Memo", isPresented: $failed) {
            Button("OK") {}
        } message: {
            Text("There was a problem creating or saving “\(recording.title)”.")
        }
    }

    private var isPartial: Bool {
        guard let draft else { return false }
        return selection.upperBound - selection.lowerBound > 0.05 && (selection.lowerBound > 0.01 || selection.upperBound < draft.duration - 0.01)
    }

    private var header: some View {
        VStack(spacing: 2) {
            HStack {
                Button { close() } label: {
                    Image(systemName: "xmark").frame(width: 44, height: 44)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel("Cancel")
                Spacer()
                Button { isConfirming = true } label: {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .opacity(draft?.isEdited == true ? 1 : 0)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .tint(draft?.isEdited == true ? .accentColor : .clear)
                .disabled(draft?.isEdited != true)
                .accessibilityLabel("Save")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            Text(recording.title).font(.headline).padding(.top, 4)
            HStack(spacing: 6) {
                Text(Format.headerDate(recording.created))
                Text(Format.duration(draft?.duration ?? recording.duration)).monospacedDigit()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
        }
    }

    private func load(_ next: EditDraft?) {
        guard let next else { return }
        draft = next
        selection = 0...next.duration
        var preview = recording
        preview.duration = next.duration
        player.load(preview, url: next.url, peaks: next.peaks)
    }

    private func apply(keeping ranges: [Range<TimeInterval>]) {
        guard let draft, !ranges.isEmpty else { return }
        player.pause()
        do {
            load(try library.edit(draft, keeping: ranges))
        } catch {
            failed = true
        }
    }

    private func save(asNew: Bool) {
        guard let draft else { return }
        player.unload()
        do {
            if asNew {
                let copy = try library.saveAsNew(draft, from: recording.id)
                session.expand(copy, player: player, library: library)
                session.selected = copy?.id ?? session.selected
            } else {
                try library.save(draft, over: recording.id)
            }
            self.draft = nil
            session.editing = nil
        } catch {
            failed = true
        }
    }

    private func close() {
        if let draft { library.discard(draft) }
        player.unload()
        session.editing = nil
    }
}

struct TrimStrip: View {
    let peaks: [Float]
    let duration: TimeInterval
    let time: TimeInterval
    @Binding var selection: ClosedRange<TimeInterval>
    private let handle: CGFloat = 14

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let x = { (t: TimeInterval) in duration > 0 ? CGFloat(t / duration) * width : 0 }
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Color.panel)
                WaveformBars(peaks: peaks, duration: duration, visible: 0...max(duration, 0.01), playhead: 0, played: Color(.label), unplayed: Color(.label), barWidth: 1, spacing: 1.5)
                    .padding(.vertical, 8)
                Rectangle()
                    .fill(Color.yellow.opacity(0.22))
                    .frame(width: max(0, x(selection.upperBound) - x(selection.lowerBound)))
                    .offset(x: x(selection.lowerBound))
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(Color.yellow, lineWidth: 3)
                            .frame(width: max(0, x(selection.upperBound) - x(selection.lowerBound)) + 2 * handle)
                            .offset(x: x(selection.lowerBound) - handle)
                    }
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: 3)
                    .padding(.vertical, -4)
                    .offset(x: x(time) - 1.5)
                grip(systemImage: "chevron.compact.left")
                    .offset(x: x(selection.lowerBound) - handle)
                    .gesture(DragGesture().onChanged { value in
                        let t = duration * Double(min(max(0, value.location.x + x(selection.lowerBound) - handle), width) / width)
                        selection = min(t, selection.upperBound - 0.1)...selection.upperBound
                    })
                grip(systemImage: "chevron.compact.right")
                    .offset(x: x(selection.upperBound))
                    .gesture(DragGesture().onChanged { value in
                        let t = duration * Double(min(max(0, value.location.x + x(selection.upperBound)), width) / width)
                        selection = selection.lowerBound...max(t, selection.lowerBound + 0.1)
                    })
            }
        }
        .frame(height: 44)
        .sensoryFeedback(.selection, trigger: selection == 0...duration)
    }

    private func grip(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.black)
            .frame(width: handle, height: 44)
            .background(Color.yellow, in: .rect(cornerRadius: 4))
            .contentShape(.rect.inset(by: -12))
    }
}
