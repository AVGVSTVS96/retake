import Foundation

public struct EditDraft: Equatable, Sendable {
    public let url: URL
    public let duration: TimeInterval
    public let peaks: [Float]
    public let isEdited: Bool
}

extension Library {
    public func draft(of id: Recording.ID) -> EditDraft? {
        guard let recording = recording(id) else { return nil }
        return EditDraft(url: url(for: recording), duration: recording.duration, peaks: peaks[id] ?? [], isEdited: false)
    }

    public func edit(_ draft: EditDraft, keeping ranges: [Range<TimeInterval>]) throws -> EditDraft {
        let target = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).edit.caf")
        let duration = try AudioFiles.render(draft.url, keeping: ranges, to: target)
        if draft.isEdited { try? FileManager.default.removeItem(at: draft.url) }
        return EditDraft(url: target, duration: duration, peaks: Peaks.slice(draft.peaks, keeping: ranges), isEdited: true)
    }

    public func discard(_ draft: EditDraft) {
        if draft.isEdited { try? FileManager.default.removeItem(at: draft.url) }
    }

    public func save(_ draft: EditDraft, over id: Recording.ID) throws {
        guard draft.isEdited else { return }
        try replaceAudio(of: id, with: draft.url, duration: draft.duration, peaks: draft.peaks)
    }

    @discardableResult
    public func saveAsNew(_ draft: EditDraft, from id: Recording.ID) throws -> Recording? {
        guard draft.isEdited, let source = recording(id) else { return nil }
        var copy = Recording(title: nextTitle(base: "\(source.title) copy"), created: .now, duration: draft.duration, file: "")
        copy.file = "\(copy.id.uuidString).caf"
        copy.folder = source.folder
        try FileManager.default.moveItem(at: draft.url, to: url(for: copy))
        insert(copy, peaks: draft.peaks)
        return copy
    }
}

extension Peaks {
    static func slice(_ bins: [Float], keeping ranges: [Range<TimeInterval>]) -> [Float] {
        ranges.flatMap { range in
            bins[min(bins.count, Int(range.lowerBound * binsPerSecond))..<min(bins.count, Int((range.upperBound * binsPerSecond).rounded(.up)))]
        }
    }
}
