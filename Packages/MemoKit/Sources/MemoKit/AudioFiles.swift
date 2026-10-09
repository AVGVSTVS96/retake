@preconcurrency import AVFoundation

enum AudioFiles {
    static func duration(of url: URL) throws -> TimeInterval {
        let file = try AVAudioFile(forReading: url)
        return Double(file.length) / file.fileFormat.sampleRate
    }

    static func takeSettings(sampleRate: Double, channels: AVAudioChannelCount) -> [String: Any] {
        [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
        ]
    }

    static func settings(for quality: AudioQuality, sampleRate: Double, channels: AVAudioChannelCount) -> [String: Any] {
        switch quality {
        case .lossy:
            [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: channels,
                AVEncoderBitRatePerChannelKey: 64_000,
            ]
        case .lossless:
            [
                AVFormatIDKey: kAudioFormatAppleLossless,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: channels,
                AVEncoderBitDepthHintKey: 16,
            ]
        }
    }

    static func transcode(_ source: URL, to target: URL, quality: AudioQuality) throws {
        let input = try AVAudioFile(forReading: source)
        let format = input.processingFormat
        try? FileManager.default.removeItem(at: target)
        let output = try AVAudioFile(
            forWriting: target,
            settings: settings(for: quality, sampleRate: format.sampleRate, channels: format.channelCount),
            commonFormat: format.commonFormat,
            interleaved: format.isInterleaved
        )
        try copy(from: input, to: output, frames: input.length)
        output.close()
    }

    static func copy(from input: AVAudioFile, to output: AVAudioFile, frames: AVAudioFramePosition) throws {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: input.processingFormat, frameCapacity: 32_768) else { return }
        var remaining = frames
        while remaining > 0 {
            try input.read(into: buffer, frameCount: AVAudioFrameCount(min(remaining, 32_768)))
            if buffer.frameLength == 0 { break }
            try output.write(from: buffer)
            remaining -= AVAudioFramePosition(buffer.frameLength)
        }
    }

    static func render(_ source: URL, keeping ranges: [Range<TimeInterval>], to target: URL) throws -> TimeInterval {
        try render(ranges.map { (source, $0) }, to: target)
    }

    static func render(_ pieces: [(URL, Range<TimeInterval>)], to target: URL) throws -> TimeInterval {
        guard let first = pieces.first else { throw CocoaError(.fileReadUnknown) }
        let format = try AVAudioFile(forReading: first.0).processingFormat
        let output = try AVAudioFile(
            forWriting: target,
            settings: takeSettings(sampleRate: format.sampleRate, channels: format.channelCount),
            commonFormat: format.commonFormat,
            interleaved: format.isInterleaved
        )
        var frames: AVAudioFramePosition = 0
        for (url, range) in pieces {
            let input = try AVAudioFile(forReading: url)
            guard input.processingFormat == format else { throw CocoaError(.fileReadCorruptFile) }
            let start = min(input.length, AVAudioFramePosition(range.lowerBound * format.sampleRate))
            let end = min(input.length, AVAudioFramePosition(range.upperBound * format.sampleRate))
            guard end > start else { continue }
            input.framePosition = start
            try copy(from: input, to: output, frames: end - start)
            frames += end - start
        }
        output.close()
        return Double(frames) / format.sampleRate
    }
}
