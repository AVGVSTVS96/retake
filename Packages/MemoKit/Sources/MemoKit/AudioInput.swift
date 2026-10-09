@preconcurrency import AVFoundation

public protocol AudioInput: AnyObject {
    func start(_ sink: @escaping @Sendable (AVAudioPCMBuffer) -> Void) throws
    func stop()
}

public enum RecorderError: Error, Equatable {
    case permissionDenied
    case noMicrophone
    case failedToStart
    case failedToSave
}

public final class MicInput: AudioInput, @unchecked Sendable {
    private let engine = AVAudioEngine()
    private var sink: (@Sendable (AVAudioPCMBuffer) -> Void)?
    private var observer: NSObjectProtocol?

    public init() {}

    public func start(_ sink: @escaping @Sendable (AVAudioPCMBuffer) -> Void) throws {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true)
        #endif
        self.sink = sink
        try run()
        observer = NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            try? self?.run()
        }
    }

    public func stop() {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        sink = nil
    }

    private func run() throws {
        let input = engine.inputNode
        input.removeTap(onBus: 0)
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0, let sink else { throw RecorderError.noMicrophone }
        try input.installAudioTap(onBus: 0, bufferSize: 2048, format: format) { buffer, _ in sink(AVAudioPCMBuffer(copying: buffer)) }
        engine.prepare()
        try engine.start()
    }
}

public final class SyntheticInput: AudioInput, @unchecked Sendable {
    private let engine = AVAudioEngine()
    private let voice = SyntheticVoice(seed: 7)
    private lazy var source = AVAudioSourceNode { [voice] _, _, frameCount, buffers in
        voice.render(frameCount, into: UnsafeMutableAudioBufferListPointer(buffers))
        return noErr
    }

    public init() {}

    public func start(_ sink: @escaping @Sendable (AVAudioPCMBuffer) -> Void) throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
        if source.engine == nil {
            engine.attach(source)
            try engine.connectNode(source, to: engine.mainMixerNode, format: format)
            engine.mainMixerNode.outputVolume = 0
        }
        try source.installAudioTap(onBus: 0, bufferSize: 2048, format: format) { buffer, _ in sink(AVAudioPCMBuffer(copying: buffer)) }
        engine.prepare()
        try engine.start()
    }

    public func stop() {
        source.removeTap(onBus: 0)
        engine.stop()
    }
}

public final class SyntheticVoice: @unchecked Sendable {
    private var state: UInt64
    private var remaining = 0
    private var amplitude: Float = 0
    private var target: Float = 0
    private var low: Float = 0

    public init(seed: UInt64) {
        state = seed
    }

    private func next() -> Float {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return Float(z ^ (z >> 31)) / Float(UInt64.max)
    }

    public func write(seconds: TimeInterval, to url: URL) throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
        let file = try AVAudioFile(forWriting: url, settings: AudioFiles.takeSettings(sampleRate: 48_000, channels: 1), commonFormat: .pcmFormatFloat32, interleaved: false)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4800)!
        var remaining = Int(seconds * 48_000)
        while remaining > 0 {
            buffer.frameLength = AVAudioFrameCount(min(4800, remaining))
            render(buffer.frameLength, into: UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList))
            try file.write(from: buffer)
            remaining -= Int(buffer.frameLength)
        }
        file.close()
    }

    func render(_ frames: UInt32, into buffers: UnsafeMutableAudioBufferListPointer) {
        guard let samples = buffers[0].mData?.assumingMemoryBound(to: Float.self) else { return }
        for frame in 0..<Int(frames) {
            if remaining == 0 {
                let speaking = next() < 0.72
                remaining = Int((speaking ? 0.06 + 0.2 * next() : 0.04 + 0.35 * next()) * 48_000)
                target = speaking ? 0.08 + 0.7 * next() * next() : 0.004
            }
            remaining -= 1
            amplitude += (target - amplitude) * 0.0025
            low += ((next() * 2 - 1) - low) * 0.18
            samples[frame] = low * amplitude * 1.6
        }
    }
}
