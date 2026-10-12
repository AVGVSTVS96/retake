@preconcurrency import AVFoundation
import Observation

@MainActor @Observable
public final class Player {
    public private(set) var current: Recording.ID?
    public private(set) var isPlaying = false
    public private(set) var duration: TimeInterval = 0
    public private(set) var options = PlaybackOptions()

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private let node = AVAudioPlayerNode()
    @ObservationIgnored private let pitch = AVAudioUnitTimePitch()
    @ObservationIgnored private let eq = AVAudioUnitEQ(numberOfBands: 3)
    @ObservationIgnored private let dynamics = AVAudioUnitEffect(audioComponentDescription: AudioComponentDescription(
        componentType: kAudioUnitType_Effect,
        componentSubType: kAudioUnitSubType_DynamicsProcessor,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    ))
    @ObservationIgnored private var file: AVAudioFile?
    @ObservationIgnored private var peaks: [Float] = []
    @ObservationIgnored private var schedule = Schedule(segments: [])
    @ObservationIgnored private var restingTime: TimeInterval = 0
    @ObservationIgnored private var generation = 0

    public init() {
        engine.attach(node)
        engine.attach(pitch)
        engine.attach(eq)
        engine.attach(dynamics)
        configureEnhance()
    }

    public func load(_ recording: Recording, url: URL, peaks: [Float]) {
        guard current != recording.id || file?.url != url else {
            setOptions(recording.playback)
            return
        }
        stopNode()
        file = try? AVAudioFile(forReading: url)
        current = recording.id
        self.peaks = peaks
        duration = file.map { Double($0.length) / $0.fileFormat.sampleRate } ?? recording.duration
        restingTime = 0
        options = recording.playback
        connect()
        applyOptions()
    }

    public func unload() {
        stopNode()
        engine.stop()
        file = nil
        current = nil
        restingTime = 0
    }

    public func time(at _: Date = .now) -> TimeInterval {
        guard isPlaying,
              let renderTime = node.lastRenderTime,
              let playerTime = node.playerTime(forNodeTime: renderTime) else { return restingTime }
        let played = Double(playerTime.sampleTime) / playerTime.sampleRate
        return min(duration, schedule.fileTime(afterPlaying: played))
    }

    public func toggle() {
        isPlaying ? pause() : play()
    }

    public func play() {
        guard file != nil, !isPlaying else { return }
        if restingTime >= duration - 0.01 { restingTime = 0 }
        activateSession()
        do {
            if !engine.isRunning { try engine.start() }
        } catch {
            return
        }
        scheduleFrom(restingTime)
        guard (try? node.playAudio()) != nil else { return }
        isPlaying = true
    }

    public func pause() {
        guard isPlaying else { return }
        restingTime = time()
        stopNode()
    }

    public func seek(to time: TimeInterval) {
        let target = min(max(0, time), duration)
        if isPlaying {
            stopNode()
            restingTime = target
            play()
        } else {
            restingTime = target
        }
    }

    public func skip(by delta: TimeInterval) {
        seek(to: time() + delta)
    }

    public func setOptions(_ options: PlaybackOptions) {
        guard options != self.options else { return }
        let skipChanged = options.skipSilence != self.options.skipSilence
        self.options = options
        applyOptions()
        if skipChanged, isPlaying { seek(to: time()) }
    }

    private func stopNode() {
        generation += 1
        node.stop()
        isPlaying = false
    }

    private func connect() {
        guard let file else { return }
        let format = file.processingFormat
        let chain: [AVAudioNode] = [node, pitch, eq, dynamics, engine.mainMixerNode]
        for (from, to) in zip(chain, chain.dropFirst()) {
            engine.disconnectNodeOutput(from)
            try? engine.connectNode(from, to: to, format: format)
        }
        engine.prepare()
    }

    private func applyOptions() {
        pitch.rate = Float(options.speed)
        eq.bypass = !options.enhance
        dynamics.bypass = !options.enhance
    }

    private func configureEnhance() {
        let bands = eq.bands
        bands[0].filterType = .highPass
        bands[0].frequency = 90
        bands[1].filterType = .parametric
        bands[1].frequency = 3_200
        bands[1].bandwidth = 1.2
        bands[1].gain = 3
        bands[2].filterType = .lowPass
        bands[2].frequency = 12_000
        bands.forEach { $0.bypass = false }
        dynamics.withAudioUnit { unit in
            let parameters: [(AudioUnitParameterID, AudioUnitParameterValue)] = [
                (kDynamicsProcessorParam_ExpansionThreshold, -42),
                (kDynamicsProcessorParam_ExpansionRatio, 4),
                (kDynamicsProcessorParam_Threshold, -18),
                (kDynamicsProcessorParam_OverallGain, 4),
            ]
            for (id, value) in parameters {
                AudioUnitSetParameter(unit, id, kAudioUnitScope_Global, 0, value, 0)
            }
        }
    }

    private func scheduleFrom(_ time: TimeInterval) {
        guard let file else { return }
        let sampleRate = file.processingFormat.sampleRate
        let ranges = options.skipSilence ? Silence.voiced(peaks: peaks, duration: duration) : [0..<duration]
        schedule = Schedule(segments: ranges.compactMap { range in
            let start = max(range.lowerBound, time)
            return start < range.upperBound ? start..<range.upperBound : nil
        })
        let generation = generation
        for (index, segment) in schedule.segments.enumerated() {
            let start = AVAudioFramePosition(segment.lowerBound * sampleRate)
            let frames = AVAudioFrameCount(max(0, min(Double(file.length - start), (segment.upperBound - segment.lowerBound) * sampleRate)))
            guard frames > 0 else { continue }
            let isLast = index == schedule.segments.count - 1
            node.scheduleSegment(file, startingFrame: start, frameCount: frames, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                guard isLast else { return }
                Task { @MainActor in
                    guard let self, self.generation == generation else { return }
                    self.restingTime = self.duration
                    self.stopNode()
                }
            }
        }
    }

    private func activateSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        if session.category != .playback {
            try? session.setCategory(.playback, mode: .default)
        }
        try? session.setActive(true)
        #endif
    }
}

struct Schedule {
    var segments: [Range<TimeInterval>]

    func fileTime(afterPlaying played: TimeInterval) -> TimeInterval {
        var remaining = played
        for segment in segments {
            let length = segment.upperBound - segment.lowerBound
            if remaining <= length { return segment.lowerBound + remaining }
            remaining -= length
        }
        return segments.last?.upperBound ?? 0
    }
}

public enum Silence {
    public static func voiced(peaks: [Float], duration: TimeInterval, threshold: Float = 0.22, minimumGap: TimeInterval = 0.6, padding: TimeInterval = 0.15) -> [Range<TimeInterval>] {
        let bin = 1 / Peaks.binsPerSecond
        var ranges: [Range<TimeInterval>] = []
        for (index, level) in peaks.enumerated() where level >= threshold {
            let start = max(0, Double(index) * bin - padding)
            let end = min(duration, Double(index + 1) * bin + padding)
            guard start < end else { continue }
            if let last = ranges.last, start - last.upperBound < minimumGap {
                ranges[ranges.count - 1] = last.lowerBound..<max(last.upperBound, end)
            } else {
                ranges.append(start..<end)
            }
        }
        return ranges.isEmpty ? [0..<duration] : ranges
    }
}
