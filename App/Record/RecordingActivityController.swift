@preconcurrency import ActivityKit
import MemoKit
import SwiftUI

@MainActor
final class RecordingActivityController {
    private var activity: Activity<RecordingActivity>?

    func update(phase: Recorder.Phase, title: String, elapsed: TimeInterval) {
        let state = RecordingActivity.ContentState(
            started: .now.addingTimeInterval(-elapsed),
            pausedElapsed: phase == .paused ? elapsed : nil
        )
        switch phase {
        case .idle:
            let ending = activity
            activity = nil
            Task { await ending?.end(nil, dismissalPolicy: .immediate) }
        case .recording, .paused:
            if let activity {
                Task { await activity.update(.init(state: state, staleDate: nil)) }
            } else if ActivityAuthorizationInfo().areActivitiesEnabled {
                activity = try? Activity.request(attributes: RecordingActivity(title: title), content: .init(state: state, staleDate: nil))
            }
        }
    }
}
