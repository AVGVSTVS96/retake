@preconcurrency import AVFoundation

final class TakeWriter: @unchecked Sendable {
    struct Result {
        var frames: AVAudioFramePosition
        var peaks: [Float]
        var sampleRate: Double
        var duration: TimeInterval { Double(frames) / sampleRate }
    }

    let url: URL
    let format: AVAudioFormat
    private let file: AVAudioFile
    private let queue = DispatchQueue(label: "memo.take-writer", qos: .userInitiated)
    private let onBins: @Sendable ([Float], AVAudioFramePosition) -> Void
    private var converter: AVAudioConverter?
    private var meter: Meter
    private var frames: AVAudioFramePosition = 0
    private var peaks: [Float] = []
    private var isOpen = true

    init(url: URL, sampleRate: Double, channels: AVAudioChannelCount, onBins: @escaping @Sendable ([Float], AVAudioFramePosition) -> Void) throws {
        self.url = url
        self.onBins = onBins
        file = try AVAudioFile(
            forWriting: url,
            settings: AudioFiles.takeSettings(sampleRate: sampleRate, channels: channels),
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        format = file.processingFormat
        meter = Meter(binFrames: Int(sampleRate / Peaks.binsPerSecond))
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        queue.async { self.write(buffer) }
    }

    func finish() -> Result {
        queue.sync {
            if isOpen {
                isOpen = false
                peaks += meter.flush()
                file.close()
            }
            return Result(frames: frames, peaks: peaks, sampleRate: format.sampleRate)
        }
    }

    private func write(_ buffer: AVAudioPCMBuffer) {
        guard isOpen, let converted = convert(buffer), converted.frameLength > 0 else { return }
        do {
            try file.write(from: converted)
        } catch {
            return
        }
        frames += AVAudioFramePosition(converted.frameLength)
        let bins = meter.ingest(converted)
        peaks += bins
        if !bins.isEmpty { onBins(bins, frames) }
    }

    private func convert(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        if buffer.format == format { return buffer }
        if converter?.inputFormat != buffer.format {
            converter = AVAudioConverter(from: buffer.format, to: format)
        }
        guard let converter else { return nil }
        let capacity = AVAudioFrameCount((Double(buffer.frameLength) * format.sampleRate / buffer.format.sampleRate).rounded(.up)) + 32
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return nil }
        var consumed = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if consumed {
                status.pointee = .noDataNow
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return buffer
        }
        return error == nil ? output : nil
    }
}
