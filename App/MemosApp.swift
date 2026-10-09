import MemoKit
import SwiftUI

@main
struct MemosApp: App {
    private let model = Model.shared
    @State private var activity = RecordingActivityController()

    private func applySettings() {
        let defaults = UserDefaults.standard
        model.library.quality = AudioQuality(rawValue: defaults.string(forKey: "audioQuality") ?? "") ?? .lossy
        model.places.setEnabled(defaults.bool(forKey: "locationNaming"))
        let days = defaults.object(forKey: "clearDeleted") as? Int ?? 30
        if days >= 0 {
            model.library.purgeDeleted(before: Calendar.current.date(byAdding: .day, value: -days, to: .now)!)
        }
    }

    var body: some Scene {
        WindowGroup {
            Root()
                .environment(model.library)
                .environment(model.recorder)
                .environment(model.player)
                .environment(model.session)
                .environment(model.places)
                .task { applySettings() }
                .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in applySettings() }
                .onChange(of: model.recorder.phase) { _, phase in
                    activity.update(phase: phase, title: model.recorder.take?.title ?? "", elapsed: model.recorder.seconds)
                }
        }
    }
}
