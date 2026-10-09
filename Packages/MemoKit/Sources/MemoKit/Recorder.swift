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
    public private(set) var live: LiveTranscriber?
    public private(set) var replacing: (id: Recording.ID, at: TimeInterval)?
    public var sampleRate = 48_000.0
    public var transcriptionLocale: Locale? = .current

    @ObservationIgnored private let library: Library
    @ObservationIgnored private let input: AudioInput
    @ObservationIgnored private var writer: TakeWriter?
    @ObservationIgnored private var events: Task<Void, Never>?
    @ObservationIgnored private var anchor = (seconds: 0.0, time: 0.0)
    @ObservationIgnored private var isStarting = false
    @ObservationIgnored private var interruptions: NotificationCenter.ObservationToken?

    public init(library: Library, input: AudioInput = MicInput()) {
        self.library = library
        self.input = input
        observeInterruptions()
    }

    public func displaySeconds(at time: TimeInterval = CACurrentMediaTime()) -> TimeInterval {
        guard phase == .recording else { return seconds }
        return seconds + min(max(0, time - anchor.time), 0.12)
    }

    public func dismissError() {
        error = nil
    }

    public func record(title: String? = nil) async {
        guard phase == .idle, !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        guard await Self.permission() else {
            error = .permissionDenied
            return
        }
        start(title: title.map { library.nextTitle(base: $0) })
    }

    public func record(replacing id: Recording.ID, at time: TimeInterval) async {
        guard phase == .idle, !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        guard await Self.permission() else {
            error = .permissionDenied
            return
        }
        start(replacing: id, at: time)
    }

    public func start(replacing id: Recording.ID, at time: TimeInterval) {
        guard phase == .idle, let recording = library.recording(id) else { return }
        replacing = (id, min(max(0, time), recording.duration))
        start(title: recording.title)
        if phase == .idle { replacing = nil }
    }

    public func start(title: String? = nil) {
        guard phase == .idle else { return }
        let take = Take(id: UUID(), title: title ?? library.nextTitle(), created: .now)
        let (stream, continuation) = AsyncStream.makeStream(of: ([Float], AVAudioFramePosition).self)
        let writer: TakeWriter
        let live = transcriptionLocale.map(LiveTranscriber.init(locale:))
        do {
            writer = try TakeWriter(url: library.newTakeURL(take.id), sampleRate: sampleRate, channels: 1) { bins, frames in
                continuation.yield((bins, frames))
            }
            try input.start { [writer] buffer in
                writer.append(buffer)
                live?.append(buffer)
            }
        } catch {
            input.stop()
            live?.cancel()
            try? FileManager.default.removeItem(at: library.newTakeURL(take.id))
            self.error = error as? RecorderError ?? .failedToStart
            return
        }
        self.writer = writer
        self.take = take
        self.live = live
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
            try input.start { [writer, live = self.live] buffer in
                writer.append(buffer)
                live?.append(buffer)
            }
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
        let live = self.live
        self.live = nil
        phase = .idle
        levels = result.peaks
        seconds = result.duration
        let replacing = self.replacing
        self.replacing = nil
        guard result.frames > 0 else {
            live?.cancel()
            try? FileManager.default.removeItem(at: writer.url)
            return nil
        }
        if let replacing {
            live?.cancel()
            do {
                try library.replace(replacing.id, at: replacing.at, with: writer.url, duration: result.duration, peaks: result.peaks)
            } catch {
                self.error = .failedToSave
                library.recoverTake(writer.url, title: take.title)
            }
            return library.recording(replacing.id)
        }
        let recording = Recording(id: take.id, title: take.title, created: take.created, duration: result.duration, file: writer.url.lastPathComponent)
        library.insert(recording, peaks: result.peaks, live: live)
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
        interruptions = NotificationCenter.default.addObserver(of: AVAudioSession.sharedInstance(), for: .didBecomeInactive) { [weak self] message in
            guard case .systemInterruption = message.deactivationResult else { return }
            self?.pause()
        }
    }
}
