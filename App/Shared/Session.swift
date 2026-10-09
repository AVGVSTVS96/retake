import MemoKit
import Observation
import SwiftUI

enum Scope: Hashable {
    case all
    case favorites
    case deleted
    case folder(Folder.ID)
}

enum SheetMode: Hashable, Identifiable {
    case recorder
    case recording(Recording.ID)

    var id: Self { self }
}

@MainActor @Observable
final class Session {
    var expanded: Recording.ID?
    var selected: Recording.ID?
    var sheet: SheetMode?
    var detent: PresentationDetent?
    var options: Recording.ID?
    var transcript: Recording.ID?
    var renaming: Recording.ID?
    var editing: Recording.ID?
}

extension Library {
    func recordings(in scope: Scope) -> [Recording] {
        switch scope {
        case .all: recordings.filter { $0.deleted == nil }
        case .favorites: recordings.filter { $0.deleted == nil && $0.isFavorite }
        case .deleted: recordings.filter { $0.deleted != nil }.sorted { $0.deleted! > $1.deleted! }
        case let .folder(id): recordings.filter { $0.deleted == nil && $0.folder == id }
        }
    }

    func title(of scope: Scope) -> String {
        switch scope {
        case .all: String(localized: "All Recordings")
        case .favorites: String(localized: "Favorites")
        case .deleted: String(localized: "Recently Deleted")
        case let .folder(id): folders.first { $0.id == id }?.name ?? ""
        }
    }
}
