import Foundation
import MemoKit
import SwiftUI

enum Demo {
    static let isEnabled = ProcessInfo.processInfo.arguments.contains("-demo")

    static func argument(_ name: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-\(name)"), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    static let samples: [(title: String, daysAgo: Double, seconds: Double, transcript: Bool)] = [
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

    @MainActor
    static func library() -> Library {
        let directory = FileManager.default.temporaryDirectory.appending(path: "demo-\(UUID().uuidString)")
        let library = Library(directory: directory)
        let scratch = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appending(path: "demo-audio")
        try? FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        let now = Calendar.current.date(bySettingHour: 9, minute: 41, second: 0, of: .now)!
        for (index, sample) in samples.enumerated().reversed() {
            let url = scratch.appending(path: "\(index)-\(sample.seconds).caf")
            if !FileManager.default.fileExists(atPath: url.path) {
                try? SyntheticVoice(seed: UInt64(index + 3)).write(seconds: sample.seconds, to: url)
            }
            guard let recording = try? library.importAudio(from: url, title: sample.title, created: now.addingTimeInterval(-sample.daysAgo * 86_400)) else { continue }
            if sample.transcript {
                library.update(recording.id) { $0.transcript = Transcript(segments: [.init(start: 0, end: sample.seconds, text: "This is a demo transcript.")]) }
            }
        }
        return library
    }

    @MainActor
    static func stage(session: Session, recorder: Recorder, library: Library, path: Binding<[Scope]>? = nil) async {
        guard isEnabled, let scene = argument("scene") else { return }
        let first = library.recordings.first?.id
        switch scene {
        case "folders":
            path?.wrappedValue = []
        case "expanded":
            session.expanded = first
        case "recording", "recording-full", "paused":
            recorder.start()
            session.sheet = .recorder
            if scene != "recording" { session.detent = .large }
            if scene == "paused" {
                try? await Task.sleep(for: .seconds(2.6))
                recorder.pause()
            }
        case "player":
            session.expanded = first
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
