@preconcurrency import AVFoundation
import CoreMedia
import Foundation
import Speech
import Testing
@testable import MemoKit

private func run(_ text: String, _ start: Double? = nil, _ end: Double? = nil) -> AttributedString {
    var run = AttributedString(text)
    if let start, let end {
        run.audioTimeRange = CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 1000), end: CMTime(seconds: end, preferredTimescale: 1000))
    }
    return run
}

private func word(_ text: String, _ start: Double, _ end: Double) -> Transcript.Segment {
    Transcript.Segment(start: start, end: end, text: text)
}

@Suite struct TranscriptTests {
    @Test func segmentIndexFindsTheWordBeingSpoken() {
        let transcript = Transcript(segments: [word("one", 0.5, 0.9), word("two", 1, 1.4), word("three", 2, 2.5)])
        #expect(transcript.segmentIndex(at: 0) == nil)
        #expect(transcript.segmentIndex(at: 0.5) == 0)
        #expect(transcript.segmentIndex(at: 0.95) == 0)
        #expect(transcript.segmentIndex(at: 1.2) == 1)
        #expect(transcript.segmentIndex(at: 2) == 2)
        #expect(transcript.segmentIndex(at: 60) == 2)
        #expect(Transcript(segments: []).segmentIndex(at: 1) == nil)
    }

    @Test func timedRunsBecomeWordsWithPunctuationAttached() {
        let text = run("Hello", 0, 0.4) + run(",") + run(" world", 0.5, 0.9) + run(".")
        #expect(Transcript.words(in: text) == [word("Hello,", 0, 0.4), word("world.", 0.5, 0.9)])
        #expect(Transcript(segments: Transcript.words(in: text)).text == "Hello, world.")
    }

    @Test func subwordRunsJoinIntoOneWord() {
        let text = run("Don", 0, 0.2) + run("'t", 0.2, 0.3) + run(" stop", 0.4, 0.8)
        #expect(Transcript.words(in: text) == [word("Don't", 0, 0.3), word("stop", 0.4, 0.8)])
    }

    @Test func phraseRunsSpreadTimeAcrossTheirWords() {
        let words = Transcript.words(in: run("ab abcdef", 1, 2.6))
        #expect(words.map(\.text) == ["ab", "abcdef"])
        #expect(abs(words[0].end - 1.4) < 0.0001)
        #expect(abs(words[1].start - 1.4) < 0.0001)
        #expect(words[1].end == 2.6)
    }

    @Test func untimedTextStillLands() {
        #expect(Transcript.words(in: run("Hi there")).map(\.text) == ["Hi", "there"])
    }

    @Test func draftReplacesVolatileWordsAsTheyFinalize() {
        var draft = TranscriptDraft()
        draft.apply([word("hello", 0, 0.4), word("wor", 0.5, 0.7)], isFinal: false, through: 0.7)
        #expect(draft.transcript.text == "hello wor")
        draft.apply([word("hello", 0, 0.4), word("world", 0.5, 0.9), word("how", 1, 1.2)], isFinal: false, through: 1.2)
        draft.apply([word("hello", 0, 0.4), word("world", 0.5, 0.9)], isFinal: true, through: 0.95)
        #expect(draft.transcript.text == "hello world how")
        draft.apply([word("how", 1, 1.2), word("are", 1.3, 1.5)], isFinal: false, through: 1.5)
        #expect(draft.transcript.text == "hello world how are")
        draft.apply([], isFinal: true, through: 2)
        #expect(draft.transcript.text == "hello world")
    }
}

private actor Calls {
    var urls: [URL] = []
    func record(_ url: URL) { urls.append(url) }
}

@MainActor
@Suite struct LibraryTranscriptionTests {
    private func makeAudio(seconds: Double) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).caf")
        try SyntheticVoice(seed: 3).write(seconds: seconds, to: url)
        return url
    }

    private func settle(_ library: Library) async {
        while let task = library.transcriptions.values.first { await task.value }
    }

    @Test func transcribesFinalizedAudioOnce() async throws {
        let calls = Calls()
        let library = makeLibrary { url in
            await calls.record(url)
            return Transcript(segments: [word("hello", 0, 0.5)])
        }
        let recording = try library.importAudio(from: makeAudio(seconds: 1))
        #expect(library.transcribing == [recording.id])
        await settle(library)
        #expect(library.transcribing.isEmpty)
        #expect(library.recording(recording.id)?.transcript?.text == "hello")
        #expect(await calls.urls.map(\.pathExtension) == ["m4a"])

        try library.duplicate(recording.id)
        await settle(library)
        #expect(library.recordings.allSatisfy { $0.transcript?.text == "hello" })
        #expect(await calls.urls.count == 1)

        try library.trim(recording.id, to: 0..<0.5)
        await settle(library)
        #expect(library.recording(recording.id)?.transcript != nil)
        #expect(await calls.urls.count == 2)
    }

    @Test func failedTranscriptionLeavesNoTranscript() async throws {
        let library = makeLibrary { _ in throw Transcriber.Failure.unsupported }
        let recording = try library.importAudio(from: makeAudio(seconds: 0.5))
        await settle(library)
        #expect(library.transcribing.isEmpty)
        #expect(library.recording(recording.id)?.transcript == nil)
    }

    @Test func recordingWorksWithLiveTranscription() async throws {
        let library = makeLibrary()
        let input = ManualInput()
        let recorder = Recorder(library: library, input: input)
        recorder.start()
        #expect(recorder.live != nil)
        input.feed(seconds: 1)
        let recording = try #require(recorder.stop())
        #expect(recorder.live == nil)
        #expect(abs(recording.duration - 1) < 0.01)
        await settle(library)
        #expect(library.transcribing.isEmpty)
    }
}

@Suite struct SpeechTranscriptionTests {
    @Test(.enabled(if: SpeechTranscriber.isAvailable)) func transcribesSpokenAudio() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).caf")
        try await speak("The quick brown fox jumps over the lazy dog.", to: url)
        let transcript: Transcript
        do {
            transcript = try await Transcriber.transcribe(url: url, locale: Locale(identifier: "en_US"))
        } catch {
            try Test.cancel("Speech transcription unavailable here: \(error)")
        }
        #expect(transcript.text.lowercased().contains("fox"))
        #expect(transcript.segments.count > 3)
        #expect(zip(transcript.segments, transcript.segments.dropFirst()).allSatisfy { $0.start <= $1.start })
    }

    private func speak(_ text: String, to url: URL) async throws {
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        nonisolated(unsafe) var file: AVAudioFile?
        nonisolated(unsafe) var failure: (any Error)?
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            synthesizer.write(utterance) { buffer in
                guard let buffer = buffer as? AVAudioPCMBuffer else { return }
                guard buffer.frameLength > 0 else {
                    file = nil
                    done.resume()
                    return
                }
                do {
                    if file == nil {
                        file = try AVAudioFile(forWriting: url, settings: buffer.format.settings, commonFormat: buffer.format.commonFormat, interleaved: buffer.format.isInterleaved)
                    }
                    try file?.write(from: buffer)
                } catch {
                    failure = error
                }
            }
        }
        if let failure { throw failure }
    }
}
