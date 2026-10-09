@preconcurrency import AVFoundation
import Observation
import QuartzCore

@MainActor @Observable
public final class Recorder {
    public enum Phase: Equatable, Sendable {
        case idle
        case recording
        case paused
    }

    public struct Take: Identifiable, Equatable, Sendable {
        public let id: UUID
        public let title: String
        public let created: Date
    }

    public private(set) var phase = Phase.idle
    public private(set) var take: Take?
    public private(set) var levels: [Float] = []
    public private(set) var seconds: TimeInterval = 0
    public private(set) var error: RecorderError?
    public var sampleRate = 48_000.0

    @ObservationIgnored private let library: Library
    @ObservationIgnored private let input: AudioInput
    @ObservationIgnored private var writer: TakeWriter?
    @ObservationIgnored private var events: Task<Void, Never>?
    @ObservationIgnored private var anchor = (seconds: 0.0, time: 0.0)
    @ObservationIgnored private var isStarting = false

    public init(library: Library, input: AudioInput = MicInput()) {
        self.library = library
        self.input = input
        observeInterruptions()
    }

    public func displaySeconds(at time: TimeInterval = CACurrentMediaTime()) -> TimeInterval {
        guard phase == .recording else { return seconds }
        return seconds + min(max(0, time - anchor.time), 0.12)
    }

    public func record() async {
        guard phase == .idle, !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        guard await Self.permission() else {
            error = .permissionDenied
            return
        }
        start()
    }

    public func start() {
        guard phase == .idle else { return }
        let take = Take(id: UUID(), title: library.nextTitle(), created: .now)
        let (stream, continuation) = AsyncStream.makeStream(of: ([Float], AVAudioFramePosition).self)
        let writer: TakeWriter
        do {
            writer = try TakeWriter(url: library.newTakeURL(take.id), sampleRate: sampleRate, channels: 1) { bins, frames in
                continuation.yield((bins, frames))
            }
            try input.start { [writer] buffer in writer.append(buffer) }
        } catch {
            input.stop()
            try? FileManager.default.removeItem(at: library.newTakeURL(take.id))
            self.error = error as? RecorderError ?? .failedToStart
            return
        }
        self.writer = writer
        self.take = take
        levels = []
        seconds = 0
        error = nil
        anchor = (0, CACurrentMediaTime())
        phase = .recording
        events = Task { [weak self] in
            for await (bins, frames) in stream {
                guard let self, self.take?.id == take.id else { return }
                self.levels += bins
                self.seconds = Double(frames) / self.sampleRate
                self.anchor = (self.seconds, CACurrentMediaTime())
            }
        }
    }

    public func pause() {
        guard phase == .recording else { return }
        input.stop()
        phase = .paused
    }

    public func resume() {
        guard phase == .paused, let writer else { return }
        do {
            try input.start { [writer] buffer in writer.append(buffer) }
            anchor = (seconds, CACurrentMediaTime())
            phase = .recording
        } catch {
            self.error = error as? RecorderError ?? .failedToStart
        }
    }

    @discardableResult
    public func stop() -> Recording? {
        guard phase != .idle, let writer, let take else { return nil }
        input.stop()
        let result = writer.finish()
        events?.cancel()
        events = nil
        self.writer = nil
        phase = .idle
        levels = result.peaks
        seconds = result.duration
        guard result.frames > 0 else {
            try? FileManager.default.removeItem(at: writer.url)
            return nil
        }
        let recording = Recording(id: take.id, title: take.title, created: take.created, duration: result.duration, file: writer.url.lastPathComponent)
        library.insert(recording, peaks: result.peaks)
        return recording
    }

    private static func permission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: true
        case .denied: false
        default: await AVAudioApplication.requestRecordPermission()
        }
    }

    private func observeInterruptions() {
        #if os(iOS)
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let began = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt).flatMap(AVAudioSession.InterruptionType.init) == .began
            guard began else { return }
            MainActor.assumeIsolated { self?.pause() }
        }
        #endif
    }
}
