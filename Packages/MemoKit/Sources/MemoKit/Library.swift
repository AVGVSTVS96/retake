import Foundation
import Observation

@MainActor @Observable
public final class Library {
    public private(set) var recordings: [Recording] = []
    public private(set) var folders: [Folder] = []
    public private(set) var peaks: [Recording.ID: [Float]] = [:]
    public var quality: AudioQuality = .lossy

    public let directory: URL
    @ObservationIgnored public private(set) var finalizing: [Recording.ID: Task<Void, Never>] = [:]

    private struct Index: Codable {
        var recordings: [Recording]
        var folders: [Folder]
    }

    public init(directory: URL) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if let data = try? Data(contentsOf: indexURL), let index = try? JSONDecoder().decode(Index.self, from: data) {
            recordings = index.recordings
            folders = index.folders
        }
        recordings.removeAll { !FileManager.default.fileExists(atPath: url(for: $0).path) }
        for recording in recordings {
            peaks[recording.id] = Peaks.read(from: peaksURL(for: recording.id))
        }
        recoverOrphans()
        recordings.sort { $0.created > $1.created }
        save()
        recordings.filter { !$0.isFinalized }.forEach(finalize)
    }

    public static func standard() -> Library {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return Library(directory: base.appending(path: "Recordings", directoryHint: .isDirectory))
    }

    private var indexURL: URL { directory.appending(path: "index.json") }

    public func url(for recording: Recording) -> URL {
        directory.appending(path: recording.file)
    }

    public func recording(_ id: Recording.ID) -> Recording? {
        recordings.first { $0.id == id }
    }

    func newTakeURL(_ id: Recording.ID) -> URL {
        directory.appending(path: "\(id.uuidString).caf")
    }

    func peaksURL(for id: Recording.ID) -> URL {
        directory.appending(path: "\(id.uuidString).peaks")
    }

    public func nextTitle(base: String = "New Recording") -> String {
        let taken = Set(recordings.map(\.title))
        guard taken.contains(base) else { return base }
        return (2...).lazy.map { "\(base) \($0)" }.first { !taken.contains($0) }!
    }

    func insert(_ recording: Recording, peaks: [Float]) {
        Peaks.write(peaks, to: peaksURL(for: recording.id))
        self.peaks[recording.id] = peaks
        recordings.insert(recording, at: recordings.firstIndex { $0.created < recording.created } ?? recordings.endIndex)
        save()
        finalize(recording)
    }

    public func update(_ id: Recording.ID, _ change: (inout Recording) -> Void) {
        guard let index = recordings.firstIndex(where: { $0.id == id }) else { return }
        change(&recordings[index])
        save()
    }

    public func replaceAudio(of id: Recording.ID, with file: URL, duration: TimeInterval, peaks: [Float]) throws {
        guard let old = recording(id) else { return }
        let name = "\(id.uuidString)-\(UUID().uuidString.prefix(8)).\(file.pathExtension)"
        try FileManager.default.moveItem(at: file, to: directory.appending(path: name))
        Peaks.write(peaks, to: peaksURL(for: id))
        self.peaks[id] = peaks
        update(id) {
            $0.file = name
            $0.duration = duration
            $0.transcript = nil
        }
        try? FileManager.default.removeItem(at: url(for: old))
        if let updated = recording(id) { finalize(updated) }
    }

    public func trim(_ id: Recording.ID, to range: Range<TimeInterval>, asNew: Bool = false) throws {
        try keep([range], of: id, asNew: asNew)
    }

    public func delete(_ range: Range<TimeInterval>, from id: Recording.ID, asNew: Bool = false) throws {
        guard let duration = recording(id)?.duration else { return }
        try keep([0..<range.lowerBound, range.upperBound..<duration].filter { !$0.isEmpty }, of: id, asNew: asNew)
    }

    private func keep(_ ranges: [Range<TimeInterval>], of id: Recording.ID, asNew: Bool) throws {
        guard let source = recording(id) else { return }
        let temporary = directory.appending(path: "\(UUID().uuidString).edit.caf")
        let duration = try AudioFiles.render(url(for: source), keeping: ranges, to: temporary)
        let bins = peaks[id] ?? []
        let kept = ranges.flatMap { range in
            bins[min(bins.count, Int(range.lowerBound * Peaks.binsPerSecond))..<min(bins.count, Int((range.upperBound * Peaks.binsPerSecond).rounded(.up)))]
        }
        guard asNew else {
            try replaceAudio(of: id, with: temporary, duration: duration, peaks: kept)
            return
        }
        var copy = Recording(title: nextTitle(base: "\(source.title) copy"), created: .now, duration: duration, file: "")
        copy.file = "\(copy.id.uuidString).caf"
        copy.folder = source.folder
        try FileManager.default.moveItem(at: temporary, to: url(for: copy))
        insert(copy, peaks: kept)
    }

    public func duplicate(_ id: Recording.ID) throws {
        guard let source = recording(id) else { return }
        var copy = Recording(title: nextTitle(base: "\(source.title) copy"), created: source.created.addingTimeInterval(0.001), duration: source.duration, file: "")
        copy.file = "\(copy.id.uuidString).\(url(for: source).pathExtension)"
        copy.folder = source.folder
        copy.playback = source.playback
        copy.transcript = source.transcript
        try FileManager.default.copyItem(at: url(for: source), to: url(for: copy))
        insert(copy, peaks: peaks[id] ?? [])
    }

    public func trash(_ ids: some Sequence<Recording.ID>, at date: Date = .now) {
        let ids = Set(ids)
        for index in recordings.indices where ids.contains(recordings[index].id) {
            recordings[index].deleted = date
        }
        save()
    }

    public func recover(_ ids: some Sequence<Recording.ID>) {
        let ids = Set(ids)
        for index in recordings.indices where ids.contains(recordings[index].id) {
            recordings[index].deleted = nil
            if let folder = recordings[index].folder, !folders.contains(where: { $0.id == folder }) {
                recordings[index].folder = nil
            }
        }
        save()
    }

    public func erase(_ ids: some Sequence<Recording.ID>) {
        let ids = Set(ids)
        for recording in recordings where ids.contains(recording.id) {
            try? FileManager.default.removeItem(at: url(for: recording))
            try? FileManager.default.removeItem(at: peaksURL(for: recording.id))
            peaks[recording.id] = nil
        }
        recordings.removeAll { ids.contains($0.id) }
        save()
    }

    public func purgeDeleted(before cutoff: Date) {
        erase(recordings.filter { ($0.deleted ?? .distantFuture) < cutoff }.map(\.id))
    }

    @discardableResult
    public func createFolder(named name: String) -> Folder {
        let folder = Folder(name: name)
        folders.append(folder)
        save()
        return folder
    }

    public func renameFolder(_ id: Folder.ID, to name: String) {
        guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[index].name = name
        save()
    }

    public func deleteFolder(_ id: Folder.ID) {
        trash(recordings.filter { $0.folder == id && $0.deleted == nil }.map(\.id))
        folders.removeAll { $0.id == id }
        save()
    }

    public func move(_ ids: some Sequence<Recording.ID>, to folder: Folder.ID?) {
        let ids = Set(ids)
        for index in recordings.indices where ids.contains(recordings[index].id) {
            recordings[index].folder = folder
        }
        save()
    }

    private func save() {
        let index = Index(recordings: recordings, folders: folders)
        guard let data = try? JSONEncoder().encode(index) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }

    private func recoverOrphans() {
        let known = Set(recordings.map(\.file))
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])) ?? []
        for file in files where ["caf", "m4a"].contains(file.pathExtension) && !known.contains(file.lastPathComponent) {
            guard let id = UUID(uuidString: String(file.deletingPathExtension().lastPathComponent.prefix(36))),
                  !recordings.contains(where: { $0.id == id }),
                  let duration = try? AudioFiles.duration(of: file), duration > 0 else {
                try? FileManager.default.removeItem(at: file)
                continue
            }
            let created = (try? file.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .now
            let recording = Recording(id: id, title: nextTitle(), created: created, duration: duration, file: file.lastPathComponent)
            recordings.append(recording)
            let computed = (try? Peaks.compute(from: file)) ?? []
            Peaks.write(computed, to: peaksURL(for: id))
            peaks[id] = computed
        }
    }

    private func finalize(_ recording: Recording) {
        guard !recording.isFinalized, finalizing[recording.id] == nil else { return }
        let source = url(for: recording)
        let quality = quality
        let target = source.deletingPathExtension().appendingPathExtension("m4a")
        finalizing[recording.id] = Task {
            let result = await Task.detached(priority: .utility) {
                Result { try AudioFiles.transcode(source, to: target, quality: quality) }
            }.value
            finalizing[recording.id] = nil
            guard case .success = result, let current = self.recording(recording.id), current.file == recording.file else {
                try? FileManager.default.removeItem(at: target)
                return
            }
            update(recording.id) { $0.file = target.lastPathComponent }
            try? FileManager.default.removeItem(at: source)
        }
    }
}

public enum AudioQuality: String, Codable, CaseIterable, Sendable {
    case lossy, lossless
}
