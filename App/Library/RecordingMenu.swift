import MemoKit
import SwiftUI

struct RecordingMenu: View {
    let recording: Recording
    var style = Style.row

    enum Style {
        case row, sheet
    }

    var body: some View {
        Menu {
            RecordingActions(recording: recording, style: style)
        } label: {
            Image(systemName: "ellipsis")
                .font(.title2)
                .frame(width: style == .row ? 28 : 44, height: style == .row ? 40 : 44, alignment: style == .row ? .trailing : .center)
                .contentShape(.rect)
        }
        .tint(style == .row ? .accentColor : .primary)
        .accessibilityLabel("More")
    }
}

struct RecordingActions: View {
    let recording: Recording
    var style = RecordingMenu.Style.row
    @Environment(Library.self) private var library
    @Environment(Session.self) private var session
    @Environment(Player.self) private var player

    private var studioVoice: Binding<Bool> {
        Binding {
            recording.playback.enhance
        } set: { on in
            library.update(recording.id) { $0.playback.enhance = on }
            if player.current == recording.id, let updated = library.recording(recording.id) { player.setOptions(updated.playback) }
        }
    }

    var body: some View {
        Section {
            ShareLink(item: library.url(for: recording), preview: SharePreview(recording.title)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        Section {
            Button("Rename", systemImage: "pencil") { session.renaming = recording.id }
            if style == .row {
                Button("Edit Recording", systemImage: "waveform") { open() }
            } else {
                Button("Trim", systemImage: "timeline.selection") { session.editing = recording.id }
            }
            if let transcript = recording.transcript {
                Button("View Transcript", systemImage: "quote.bubble") { open { session.transcript = recording.id } }
                Button("Copy Transcript", systemImage: "text.quote") { UIPasteboard.general.string = transcript.text }
            }
        }
        Section {
            Button("Options", systemImage: "slider.horizontal.3") { open { session.options = recording.id } }
            Toggle("Studio Voice", systemImage: "waveform.and.person.filled", isOn: studioVoice)
        }
        Section {
            Button(recording.isFavorite ? "Unfavorite" : "Favorite", systemImage: recording.isFavorite ? "heart.slash" : "heart") {
                library.update(recording.id) { $0.isFavorite.toggle() }
            }
            Button("Duplicate", systemImage: "plus.square.on.square") { try? library.duplicate(recording.id) }
            Menu("Move", systemImage: "folder") {
                Button("All Recordings") { library.move([recording.id], to: nil) }
                ForEach(library.folders) { folder in
                    Button(folder.name) { library.move([recording.id], to: folder.id) }
                }
            }
        }
    }

    private func open(then show: () -> Void = {}) {
        session.sheet = .recording(recording.id)
        show()
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
