import AVFoundation
import MemoKit
import SwiftUI

enum Demo {
    static let isEnabled = ProcessInfo.processInfo.arguments.contains("-demo")

    static func argument(_ name: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-\(name)"), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    struct Sample: Decodable {
        let title: String
        let created: Date
        let seconds: Double
        let transcript: Bool
    }

    /// The list a reference recording shows, passed as JSON in `DEMO_FIXTURE` so a parity take can match
    /// footage of another library without that library entering the repo.
    struct Fixture: Decodable {
        var place: String?
        var recordings: [Sample]
    }

    static let fixture: Fixture? = ProcessInfo.processInfo.environment["DEMO_FIXTURE"].flatMap { json in
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Fixture.self, from: Data(json.utf8))
    }

    static func samples(now: Date) -> [Sample] {
        let defaults: [(title: String, daysAgo: Double, seconds: Double, transcript: Bool)] = [
            ("Chorus idea", 0, 13, true),
            ("Standup notes", 0.05, 7, false),
            ("Call with Maya", 0.08, 19, true),
            ("Coffee shop ambience", 2, 10, false),
            ("Melody in the car", 3, 7, false),
            ("Lecture: signals", 16, 14, true),
            ("Ocean Beach waves", 29, 8, false),
            ("Grocery list", 44, 11, false),
            ("Bridge lyrics", 52, 11, false),
            ("Interview take 2", 70, 68, true),
        ]
        return fixture?.recordings ?? defaults.map {
            Sample(title: $0.title, created: now.addingTimeInterval(-$0.daysAgo * 86_400), seconds: $0.seconds, transcript: $0.transcript)
        }
    }

    @MainActor
    static func library() -> Library {
        let directory = FileManager.default.temporaryDirectory.appending(path: "demo-\(UUID().uuidString)")
        let library = Library(directory: directory)
        let scratch = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appending(path: "demo-audio")
        try? FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        let now = Calendar.current.date(bySettingHour: 9, minute: 41, second: 0, of: .now)!
        for (index, sample) in samples(now: now).enumerated().reversed() {
            let url = scratch.appending(path: fixture == nil ? "\(index)-\(sample.seconds)-v2.caf" : "silence-\(sample.seconds).caf")
            if !FileManager.default.fileExists(atPath: url.path) {
                let partial = scratch.appending(path: "\(UUID().uuidString).partial.caf")
                if fixture == nil {
                    try? SyntheticVoice(seed: UInt64(index + 3)).write(seconds: sample.seconds, to: partial)
                } else {
                    try? silence(seconds: sample.seconds, to: partial)
                }
                try? FileManager.default.moveItem(at: partial, to: url)
            }
            guard let recording = try? library.importAudio(from: url, title: sample.title, created: sample.created) else { continue }
            if sample.transcript {
                library.update(recording.id) { $0.transcript = Transcript(segments: [.init(start: 0, end: sample.seconds, text: "This is a demo transcript.")]) }
            }
        }
        return library
    }

    /// Fixture rows run for minutes and nobody plays them, so they're silent at a low rate: cheap to write and finalize.
    private static func silence(seconds: Double, to url: URL) throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: 8_000, channels: 1)!
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 80_000)!
        var remaining = Int(seconds * format.sampleRate)
        while remaining > 0 {
            buffer.frameLength = AVAudioFrameCount(min(80_000, remaining))
            try file.write(from: buffer)
            remaining -= Int(buffer.frameLength)
        }
    }

    @MainActor
    static func stage(session: Session, recorder: Recorder, player: Player, library: Library, path: Binding<[Scope]>? = nil) async {
        guard isEnabled, let scene = argument("scene") else { return }
        let first = library.recordings.first?.id
        switch scene {
        case "folders":
            path?.wrappedValue = []
        case "expanded":
            session.expand(library.recordings.first, player: player, library: library)
        case "recording", "recording-full", "paused":
            recorder.start()
            session.sheet = .recorder
            if scene != "recording" { session.detent = .large }
            if scene == "paused" {
                try? await Task.sleep(for: .seconds(2.6))
                recorder.pause()
            }
        case "player":
            session.expand(library.recordings.first, player: player, library: library)
            session.sheet = first.map { .recording($0) }
        case "options":
            session.sheet = first.map { .recording($0) }
            session.options = first
        case "trim":
            session.sheet = first.map { .recording($0) }
            session.editing = first
        case "transcript":
            session.sheet = first.map { .recording($0) }
            session.transcript = first
        case "deleted":
            library.trash(library.recordings.suffix(3).map(\.id), at: .now.addingTimeInterval(-86_400))
            path?.wrappedValue = [.deleted]
        default:
            break
        }
    }
}
