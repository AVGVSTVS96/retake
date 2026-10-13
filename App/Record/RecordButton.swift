import MemoKit
import SwiftUI

struct RecordButton: View {
    @Environment(Recorder.self) private var recorder
    @Environment(Player.self) private var player
    @Environment(Session.self) private var session
    @Environment(LocationNamer.self) private var places

    var body: some View {
        Button {
            player.pause()
            withAnimation(.row) { session.expanded = nil }
            Task { await recorder.record(title: places.place) }
        } label: {
            Circle()
                .fill(Color.record)
                .frame(width: Metrics.recordDot, height: Metrics.recordDot)
                .padding(Metrics.recordRing)
        }
        .buttonStyle(RecordButtonStyle())
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel("Record")
        .disabled(recorder.phase != .idle)
        .alert("Microphone Access", isPresented: Binding(get: { recorder.error == .permissionDenied }, set: { _ in recorder.dismissError() })) {
            Button("OK") {}
        } message: {
            Text("Allow microphone access in Settings to record voice memos.")
        }
    }
}

private struct RecordButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(duration: 0.3, bounce: 0.4), value: configuration.isPressed)
    }
}
