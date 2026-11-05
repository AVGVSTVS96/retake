import AppIntents

struct StopRecordingIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop Recording"
    static let description = IntentDescription("Stops the current recording.")

    @MainActor
    func perform() async throws -> some IntentResult {
        RecordingIntentHandler.stop?()
        return .result()
    }
}

struct RecordVoiceMemoIntent: AppIntent {
    static let title: LocalizedStringResource = "Record Voice Memo"
    static let description = IntentDescription("Record personal notes, musical ideas, and more.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        await RecordingIntentHandler.record?()
        return .result()
    }
}

@MainActor
enum RecordingIntentHandler {
    static var record: (() async -> Void)?
    static var stop: (() -> Void)?
}
