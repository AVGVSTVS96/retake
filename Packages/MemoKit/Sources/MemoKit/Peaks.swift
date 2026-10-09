@preconcurrency import AVFoundation

public enum Peaks {
    public static let binsPerSecond = 50.0

    public static func level(_ peak: Float) -> Float {
        guard peak > 0 else { return 0 }
        return min(1, max(0, (20 * log10(peak) + 50) / 50))
    }

    static func read(from url: URL) -> [Float] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return data.map { Float($0) / 255 }
    }

    static func write(_ peaks: [Float], to url: URL) {
        try? Data(peaks.map { UInt8((min(1, max(0, $0)) * 255).rounded()) }).write(to: url, options: .atomic)
    }

    public static func compute(from url: URL) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let binFrames = AVAudioFrameCount(format.sampleRate / binsPerSecond)
        var meter = Meter(binFrames: Int(binFrames))
        var peaks: [Float] = []
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: binFrames * 64) else { return [] }
        while file.framePosition < file.length {
            try file.read(into: buffer)
            if buffer.frameLength == 0 { break }
            peaks += meter.ingest(buffer)
        }
        return peaks + meter.flush()
    }
}

struct Meter {
    let binFrames: Int
    private var peak: Float = 0
    private var count = 0

    init(binFrames: Int) {
        self.binFrames = max(1, binFrames)
    }

    mutating func ingest(_ buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channels = buffer.floatChannelData else { return [] }
        let channelCount = Int(buffer.format.channelCount)
        var bins: [Float] = []
        for frame in 0..<Int(buffer.frameLength) {
            for channel in 0..<channelCount {
                peak = max(peak, abs(channels[channel][frame]))
            }
            count += 1
            if count == binFrames {
                bins.append(Peaks.level(peak))
                peak = 0
                count = 0
            }
        }
        return bins
    }

    mutating func flush() -> [Float] {
        defer { peak = 0; count = 0 }
        return count > 0 ? [Peaks.level(peak)] : []
    }
}
