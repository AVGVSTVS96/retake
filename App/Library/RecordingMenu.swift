import MemoKit
import SwiftUI

struct RecordingMenu: View {
    let recording: Recording
    var style = Style.row
    @Environment(Library.self) private var library
    @Environment(Session.self) private var session
    @Environment(Player.self) private var player

    enum Style {
        case row, sheet
    }

    var body: some View {
        Menu {
            RecordingActions(recording: recording)
        } label: {
            Image(systemName: "ellipsis")
                .font(style == .row ? .body.weight(.semibold) : .body.weight(.medium))
                .frame(width: style == .row ? 28 : 44, height: style == .row ? 28 : 44)
                .contentShape(.rect)
        }
        .tint(style == .row ? .accentColor : .primary)
        .accessibilityLabel("More")
    }
}

struct RecordingActions: View {
    let recording: Recording
    @Environment(Library.self) private var library
    @Environment(Session.self) private var session
    @Environment(Player.self) private var player

    var body: some View {
        Section {
            Button("Edit Recording", systemImage: "waveform") { session.sheet = .recording(recording.id) }
            Button("Trim", systemImage: "timeline.selection") {
                session.sheet = .recording(recording.id)
                session.editing = recording.id
            }
            Button("Rename", systemImage: "pencil") { session.renaming = recording.id }
            Button("Duplicate", systemImage: "plus.square.on.square") { try? library.duplicate(recording.id) }
            ShareLink(item: library.url(for: recording), preview: SharePreview(recording.title)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        Section {
            if let transcript = recording.transcript {
                Button("Copy Transcript", systemImage: "doc.on.doc") { UIPasteboard.general.string = transcript.text }
            }
            Button(recording.isFavorite ? "Unfavorite" : "Favorite", systemImage: recording.isFavorite ? "heart.slash" : "heart") {
                library.update(recording.id) { $0.isFavorite.toggle() }
            }
            Menu("Move to Folder", systemImage: "folder") {
                Button("All Recordings") { library.move([recording.id], to: nil) }
                ForEach(library.folders) { folder in
                    Button(folder.name) { library.move([recording.id], to: folder.id) }
                }
            }
        }
        Button("Delete", systemImage: "trash", role: .destructive) {
            if player.current == recording.id { player.unload() }
            if session.expanded == recording.id { session.expanded = nil }
            library.trash([recording.id])
        }
    }
}

struct SelectionToolbar: ToolbarContent {
    let scope: Scope
    @Binding var selection: Set<Recording.ID>
    let recordings: [Recording]
    let done: () -> Void
    @Environment(Library.self) private var library

    var body: some ToolbarContent {
        if scope == .deleted {
            ToolbarItem(placement: .bottomBar) {
                Button(selection.isEmpty ? "Recover All" : "Recover") {
                    library.recover(selection.isEmpty ? recordings.map(\.id) : Array(selection))
                    done()
                }
            }
            ToolbarSpacer(placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                Button(selection.isEmpty ? "Delete All" : "Delete", role: .destructive) {
                    library.erase(selection.isEmpty ? recordings.map(\.id) : Array(selection))
                    done()
                }
            }
        } else {
            ToolbarItem(placement: .bottomBar) {
                Menu("Move", systemImage: "folder") {
                    Button("All Recordings") { library.move(selection, to: nil); done() }
                    ForEach(library.folders) { folder in
                        Button(folder.name) { library.move(selection, to: folder.id); done() }
                    }
                }
                .disabled(selection.isEmpty)
            }
            ToolbarSpacer(placement: .bottomBar)
            ToolbarItem(placement: .status) {
                Text(selection.isEmpty ? String(localized: "Select Items") : String(localized: "\(selection.count) Selected"))
                    .font(.subheadline.weight(.semibold))
            }
            ToolbarSpacer(placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    library.trash(selection)
                    done()
                }
                .disabled(selection.isEmpty)
            }
        }
    }
}
