import MemoKit
import SwiftUI

@main
struct MemosApp: App {
    @State private var library: Library
    @State private var recorder: Recorder
    @State private var player = Player()

    init() {
        let library = Demo.isEnabled ? Demo.library() : Library.standard()
        _library = State(initialValue: library)
        _recorder = State(initialValue: Recorder(library: library, input: Demo.isEnabled ? SyntheticInput() : MicInput()))
    }

    private func applySettings() {
        let defaults = UserDefaults.standard
        library.quality = AudioQuality(rawValue: defaults.string(forKey: "audioQuality") ?? "") ?? .lossy
        let days = defaults.object(forKey: "clearDeleted") as? Int ?? 30
        if days >= 0 {
            library.purgeDeleted(before: Calendar.current.date(byAdding: .day, value: -days, to: .now)!)
        }
    }

    var body: some Scene {
        WindowGroup {
            Root()
                .environment(library)
                .environment(recorder)
                .environment(player)
                .task { applySettings() }
                .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in applySettings() }
        }
    }
}
