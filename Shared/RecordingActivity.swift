import ActivityKit
import Foundation

nonisolated struct RecordingActivity: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var started: Date
        var pausedElapsed: TimeInterval?
    }

    var title: String
}
