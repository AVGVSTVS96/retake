import Foundation

public struct Recording: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var created: Date
    public var duration: TimeInterval
    public var file: String
    public var folder: Folder.ID?
    public var isFavorite = false
    public var deleted: Date?
    public var playback = PlaybackOptions()
    public var transcript: Transcript?

    public init(id: UUID = UUID(), title: String, created: Date, duration: TimeInterval, file: String) {
        self.id = id
        self.title = title
        self.created = created
        self.duration = duration
        self.file = file
    }

    public var isFinalized: Bool { !file.hasSuffix(".caf") }
}

public struct PlaybackOptions: Codable, Hashable, Sendable {
    public var speed = 1.0
    public var skipSilence = false
    public var enhance = false

    public init() {}

    public var isDefault: Bool { self == PlaybackOptions() }
}

public struct Transcript: Codable, Hashable, Sendable {
    public struct Segment: Codable, Hashable, Sendable {
        public var start: TimeInterval
        public var end: TimeInterval
        public var text: String

        public init(start: TimeInterval, end: TimeInterval, text: String) {
            self.start = start
            self.end = end
            self.text = text
        }
    }

    public var segments: [Segment]

    public init(segments: [Segment]) {
        self.segments = segments
    }

    public var text: String { segments.map(\.text).joined(separator: " ") }

    public func segmentIndex(at time: TimeInterval) -> Int? {
        var low = 0
        var high = segments.count
        while low < high {
            let middle = (low + high) / 2
            if segments[middle].start <= time {
                low = middle + 1
            } else {
                high = middle
            }
        }
        return low == 0 ? nil : low - 1
    }
}

public struct Folder: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
