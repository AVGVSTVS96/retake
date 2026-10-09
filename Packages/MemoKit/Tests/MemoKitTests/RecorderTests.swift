@preconcurrency import AVFoundation
import Foundation
import Testing
@testable import MemoKit

final class ManualInput: AudioInput, @unchecked Sendable {
    let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
    private var sink: (@Sendable (AVAudioPCMBuffer) -> Void)?
    var isRunning: Bool { sink != nil }

    func start(_ sink: @escaping @Sendable (AVAudioPCMBuffer) -> Void) throws {
        self.sink = sink
    }

    func stop() {
        sink = nil
    }

    func feed(seconds: Double, amplitude: Float = 0.5) {
        var remaining = AVAudioFrameCount(seconds * format.sampleRate)
        while remaining > 0, let sink {
            let count = min(remaining, 4096)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count)!
            buffer.frameLength = count
            for channel in 0..<2 {
                for frame in 0..<Int(count) {
                    buffer.floatChannelData![channel][frame] = amplitude * sin(Float(frame) * 0.05)
                }
            }
            sink(buffer)
            remaining -= count
        }
    }
}

@MainActor
func makeLibrary(transcriber: Library.Transcribe? = nil) -> Library {
    Library(directory: FileManager.default.temporaryDirectory.appending(path: "memokit-\(UUID().uuidString)"), transcriber: transcriber)
}

@MainActor
@Suite struct RecorderTests {
    @Test func recordStopSavesExactDuration() async throws {
        let library = makeLibrary()
        let input = ManualInput()
        let recorder = Recorder(library: library, input: input)
        recorder.start()
        #expect(recorder.phase == .recording)
        input.feed(seconds: 2)
        let recording = try #require(recorder.stop())
        #expect(recorder.phase == .idle)
        #expect(!input.isRunning)
        #expect(abs(recording.duration - 2) < 0.01)
        #expect(library.recordings.map(\.id) == [recording.id])
        #expect(FileManager.default.fileExists(atPath: library.url(for: recording).path))
        #expect(abs(Double(library.peaks[recording.id]!.count) - 2 * Peaks.binsPerSecond) <= 1)
    }

    @Test func emptyTakeLeavesNothingBehind() throws {
        let library = makeLibrary()
        let recorder = Recorder(library: library, input: ManualInput())
        recorder.start()
        #expect(recorder.stop() == nil)
        #expect(library.recordings.isEmpty)
        let files = try FileManager.default.contentsOfDirectory(atPath: library.directory.path).filter { $0.hasSuffix(".caf") }
        #expect(files.isEmpty)
    }

    @Test func hammeringRecordStopNeverLosesATake() async throws {
        let library = makeLibrary()
        let input = ManualInput()
        let recorder = Recorder(library: library, input: input)
        var expected: [UUID] = []
        for cycle in 0..<300 {
            recorder.start()
            recorder.start()
            input.feed(seconds: 0.05 + Double(cycle % 7) * 0.01)
            if cycle % 5 == 0 {
                recorder.pause()
                input.feed(seconds: 1)
                recorder.resume()
                input.feed(seconds: 0.02)
            }
            let recording = try #require(recorder.stop())
            #expect(recorder.stop() == nil)
            expected.append(recording.id)
        }
        #expect(Set(library.recordings.map(\.id)) == Set(expected))
        #expect(Set(library.recordings.map(\.title)).count == 300)
        for task in library.finalizing.values { await task.value }
        for recording in library.recordings {
            #expect(recording.isFinalized)
            let duration = try AudioFiles.duration(of: library.url(for: recording))
            #expect(abs(duration - recording.duration) < 0.03)
        }
    }

    @Test func pausedAudioIsNotRecorded() throws {
        let library = makeLibrary()
        let input = ManualInput()
        let recorder = Recorder(library: library, input: input)
        recorder.start()
        input.feed(seconds: 1)
        recorder.pause()
        input.feed(seconds: 5)
        recorder.resume()
        input.feed(seconds: 1)
        let recording = try #require(recorder.stop())
        #expect(abs(recording.duration - 2) < 0.01)
    }

    @Test func newTakeStartsClean() async throws {
        let library = makeLibrary()
        let input = ManualInput()
        let recorder = Recorder(library: library, input: input)
        recorder.start()
        input.feed(seconds: 3)
        recorder.stop()
        recorder.start()
        await Task.yield()
        #expect(recorder.levels.isEmpty)
        #expect(recorder.seconds == 0)
        #expect(recorder.take?.title == "New Recording 2")
        input.feed(seconds: 0.5)
        let second = try #require(recorder.stop())
        #expect(abs(second.duration - 0.5) < 0.01)
        #expect(recorder.levels.count == 25)
    }
}

@MainActor
@Suite struct LibraryTests {
    @Test func survivesRelaunchAndRecoversOrphans() async throws {
        let library = makeLibrary()
        let input = ManualInput()
        let recorder = Recorder(library: library, input: input)
        recorder.start()
        input.feed(seconds: 1)
        let saved = try #require(recorder.stop())
        for task in library.finalizing.values { await task.value }

        let orphanID = UUID()
        let orphan = try AVAudioFile(forWriting: library.directory.appending(path: "\(orphanID.uuidString).caf"), settings: AudioFiles.takeSettings(sampleRate: 48_000, channels: 1), commonFormat: .pcmFormatFloat32, interleaved: false)
        let buffer = AVAudioPCMBuffer(pcmFormat: orphan.processingFormat, frameCapacity: 48_000)!
        buffer.frameLength = 48_000
        try orphan.write(from: buffer)
        orphan.close()

        let reopened = Library(directory: library.directory)
        #expect(Set(reopened.recordings.map(\.id)) == [saved.id, orphanID])
        #expect(reopened.recording(orphanID)?.title == "New Recording 2")
        for task in reopened.finalizing.values { await task.value }
        #expect(reopened.recordings.allSatisfy { $0.isFinalized })
    }

    @Test func trashRecoverErase() throws {
        let library = makeLibrary()
        let input = ManualInput()
        let recorder = Recorder(library: library, input: input)
        recorder.start()
        input.feed(seconds: 0.5)
        let recording = try #require(recorder.stop())
        let folder = library.createFolder(named: "Ideas")
        library.move([recording.id], to: folder.id)
        library.deleteFolder(folder.id)
        #expect(library.recording(recording.id)?.deleted != nil)
        library.recover([recording.id])
        #expect(library.recording(recording.id)?.folder == nil)
        library.trash([recording.id], at: .distantPast)
        library.purgeDeleted(before: .now)
        #expect(library.recordings.isEmpty)
    }
}

@MainActor
@Suite struct EditTests {
    @Test func trimAndDeleteRanges() async throws {
        let library = makeLibrary()
        let input = ManualInput()
        let recorder = Recorder(library: library, input: input)
        recorder.start()
        input.feed(seconds: 10)
        let recording = try #require(recorder.stop())
        for task in library.finalizing.values { await task.value }

        try library.trim(recording.id, to: 2..<8)
        #expect(abs(library.recording(recording.id)!.duration - 6) < 0.01)
        #expect(library.peaks[recording.id]!.count == 300)

        try library.delete(1..<2, from: recording.id, asNew: true)
        #expect(library.recordings.count == 2)
        let copy = try #require(library.recordings.first { $0.id != recording.id })
        #expect(abs(copy.duration - 5) < 0.01)
        #expect(copy.title == "New Recording copy")
        for task in library.finalizing.values { await task.value }
        #expect(library.recordings.allSatisfy { $0.isFinalized })
        #expect(abs(try AudioFiles.duration(of: library.url(for: library.recording(recording.id)!)) - 6) < 0.03)
    }
}

@MainActor
@Suite struct DraftTests {
    @Test func draftsChainAndSaveAsNew() async throws {
        let library = makeLibrary()
        let input = ManualInput()
        let recorder = Recorder(library: library, input: input)
        recorder.start()
        input.feed(seconds: 6)
        let recording = try #require(recorder.stop())
        let original = try #require(library.draft(of: recording.id))
        #expect(!original.isEdited)
        let trimmed = try library.edit(original, keeping: [1..<5])
        let cut = try library.edit(trimmed, keeping: [0..<1, 2..<4])
        #expect(abs(cut.duration - 3) < 0.01)
        #expect(!FileManager.default.fileExists(atPath: trimmed.url.path))
        let copy = try #require(try library.saveAsNew(cut, from: recording.id))
        #expect(abs(copy.duration - 3) < 0.01)
        #expect(abs(library.recording(recording.id)!.duration - 6) < 0.01)
    }
}
