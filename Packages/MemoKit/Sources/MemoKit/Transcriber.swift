@preconcurrency import AVFoundation
import Observation
import Speech

public enum Transcriber {
    public enum Failure: Error, Equatable {
        case unsupported
        case notInstalled
    }

    public static func transcribe(url: URL, locale: Locale) async throws -> Transcript {
        let transcriber = try await module(for: locale, preset: .timedWords)
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await request.downloadAndInstall()
        }
        let file = try AVAudioFile(forReading: url)
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        async let segments = transcriber.results.reduce(into: [Transcript.Segment]()) { segments, result in
            if result.isFinal { segments += Transcript.words(in: result.text) }
        }
        if let end = try await analyzer.analyzeSequence(from: file) {
            try await analyzer.finalizeAndFinish(through: end)
        } else {
            await analyzer.cancelAndFinishNow()
        }
        return Transcript(segments: try await segments)
    }

    static func module(for locale: Locale, preset: SpeechTranscriber.Preset) async throws -> SpeechTranscriber {
        guard SpeechTranscriber.isAvailable, let supported = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else {
            throw Failure.unsupported
        }
        return SpeechTranscriber(locale: supported, preset: preset)
    }
}

@MainActor @Observable
public final class LiveTranscriber {
    public private(set) var transcript = Transcript(segments: [])
    public private(set) var isAvailable = true

    @ObservationIgnored private let buffers: AsyncStream<AVAudioPCMBuffer>.Continuation
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var draft = TranscriptDraft()

    public init(locale: Locale) {
        let (stream, buffers) = AsyncStream.makeStream(of: AVAudioPCMBuffer.self)
        self.buffers = buffers
        task = Task.detached(priority: .userInitiated) { [self] in
            do {
                try await run(stream, locale: locale)
            } catch {
                buffers.finish()
                await markUnavailable()
            }
        }
    }

    public nonisolated func append(_ buffer: AVAudioPCMBuffer) {
        buffers.yield(buffer)
    }

    public func finish() async -> Transcript? {
        buffers.finish()
        await task?.value
        return isAvailable ? transcript : nil
    }

    public func cancel() {
        buffers.finish()
        task?.cancel()
    }

    private nonisolated func run(_ buffers: AsyncStream<AVAudioPCMBuffer>, locale: Locale) async throws {
        let transcriber = try await Transcriber.module(for: locale, preset: .timeIndexedProgressiveTranscription)
        guard await AssetInventory.status(forModules: [transcriber]) == .installed else { throw Transcriber.Failure.notInstalled }
        let converter = try await AnalyzerInputConverter.converter(compatibleWith: [transcriber])
        let (inputs, feed) = AsyncStream.makeStream(of: AnalyzerInput.self)
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        try await analyzer.start(inputSequence: inputs)
        async let results: Void = collect(transcriber.results)
        do {
            for await buffer in buffers {
                try converter.convert(buffer, at: nil).forEach { feed.yield($0) }
            }
            try Task.checkCancellation()
            try converter.flush().forEach { feed.yield($0) }
            feed.finish()
            try await analyzer.finalizeAndFinishThroughEndOfInput()
        } catch {
            await analyzer.cancelAndFinishNow()
            throw error
        }
        try await results
    }

    private nonisolated func collect(_ results: some AsyncSequence<SpeechTranscriber.Result, any Error>) async throws {
        for try await result in results {
            await apply(Transcript.words(in: result.text), isFinal: result.isFinal, through: result.range.end.seconds)
        }
    }

    private func markUnavailable() {
        isAvailable = false
    }

    private func apply(_ words: [Transcript.Segment], isFinal: Bool, through end: TimeInterval) {
        draft.apply(words, isFinal: isFinal, through: end)
        transcript = draft.transcript
    }
}

struct TranscriptDraft {
    private(set) var final: [Transcript.Segment] = []
    private(set) var volatile: [Transcript.Segment] = []

    var transcript: Transcript { Transcript(segments: final + volatile) }

    mutating func apply(_ words: [Transcript.Segment], isFinal: Bool, through end: TimeInterval) {
        if isFinal {
            final += words
            volatile.removeAll { $0.start < end }
        } else {
            volatile = words
        }
    }
}

extension Transcript {
    static func words(in text: AttributedString) -> [Segment] {
        var words: [Segment] = []
        var continuesWord = false
        for (time, range) in text.runs[\.audioTimeRange] {
            let piece = String(text[range].characters)
            let parts = piece.split(whereSeparator: \.isWhitespace)
            let start = time?.start.seconds ?? words.last?.end ?? 0
            let end = time?.end.seconds ?? start
            let length = Double(parts.reduce(0) { $0 + $1.count })
            var offset = 0.0
            for (index, part) in parts.enumerated() {
                let from = start + (end - start) * offset / length
                offset += Double(part.count)
                let to = start + (end - start) * offset / length
                if index == 0, continuesWord, piece.first?.isWhitespace == false {
                    words[words.count - 1].text += part
                    words[words.count - 1].end = max(words[words.count - 1].end, to)
                } else {
                    words.append(Segment(start: from, end: to, text: String(part)))
                }
            }
            if let last = piece.last { continuesWord = !last.isWhitespace }
        }
        return words
    }
}

extension SpeechTranscriber.Preset {
    static let timedWords = SpeechTranscriber.Preset(transcriptionOptions: [], reportingOptions: [], attributeOptions: [.audioTimeRange])
}
