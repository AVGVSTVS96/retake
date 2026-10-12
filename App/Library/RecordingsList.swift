import MemoKit
import SwiftUI

struct RecordingsList: View {
    let scope: Scope
    var isSplit = false
    @Environment(Library.self) private var library
    @Environment(Session.self) private var session
    @Environment(Player.self) private var player
    @State private var query = ""
    @State private var isSearching = false
    @State private var selection = Set<Recording.ID>()
    @State private var editMode = EditMode.inactive
    @State private var newTitle = ""

    private var recordings: [Recording] {
        let all = library.recordings(in: scope)
        let query = isSplit ? session.query : query
        guard !query.isEmpty else { return all }
        return all.filter { $0.title.localizedStandardContains(query) || ($0.transcript?.text.localizedStandardContains(query) ?? false) }
    }

    var body: some View {
        @Bindable var session = session
        List(selection: editMode.isEditing ? $selection : nil) {
            ForEach(recordings) { recording in
                RecordingRow(recording: recording, scope: scope, isExpanded: !isSplit && session.expanded == recording.id && !editMode.isEditing)
                    .contentShape(.rect)
                    .onTapGesture { toggle(recording) }
                    .listRowBackground(isSplit && session.selected == recording.id && !editMode.isEditing ? selectionBackground : nil)
                    .environment(\.isSelectedRow, isSplit && session.selected == recording.id && !editMode.isEditing)
                    .listRowSeparator(isSplit && session.selected == recording.id ? .hidden : .automatic)
                    .swipeActions(edge: .trailing) { trailingActions(recording) }
                    .listRowInsets(.init(top: 0, leading: Metrics.rowInset, bottom: 0, trailing: Metrics.rowInset))
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, $editMode)
        .animation(.smooth(duration: 0.32), value: recordings.map(\.id))
        .safeAreaPadding(.bottom, scope == .deleted ? 0 : Metrics.recordDot + 2 * Metrics.recordRing + 10)
        .overlay(alignment: .bottom) {
            if isSplit, scope != .deleted {
                RecordButton().padding(.bottom, 6)
            }
        }
        .overlay {
            if recordings.isEmpty, query.isEmpty, session.query.isEmpty {
                ContentUnavailableView {
                    Label("No Recordings", systemImage: "folder")
                } description: {
                    if scope != .deleted { Text("Tap the Record button to start a Voice Memo") }
                }
            } else if recordings.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .navigationTitle(library.title(of: scope))
        .navigationSubtitle(isSplit ? String(localized: "\(recordings.count) Recordings") : "")
        .modifier(SearchOnDemand(query: $query, isSearching: $isSearching, prompt: searchPrompt))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(editMode.isEditing ? "Done" : "Select") {
                    withAnimation { editMode = editMode.isEditing ? .inactive : .active }
                    selection = []
                }
                .fontWeight(editMode.isEditing ? .semibold : .regular)
                .disabled(recordings.isEmpty && !editMode.isEditing)
            }
            if !isSplit {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Search", systemImage: "magnifyingglass") { isSearching = true }
                }
            }
            if editMode.isEditing {
                SelectionToolbar(scope: scope, selection: $selection, recordings: recordings) {
                    withAnimation { editMode = .inactive }
                }
            }
        }
        .toolbar(editMode.isEditing ? .visible : .hidden, for: .bottomBar)
        .alert("Rename", isPresented: Binding(get: { session.renaming != nil }, set: { if !$0 { session.renaming = nil } })) {
            TextField("Name", text: $newTitle)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                if let id = session.renaming, !trimmed.isEmpty { library.update(id) { $0.title = trimmed } }
            }
        } message: {
            Text("Enter a name for this voice memo.")
        }
        .onChange(of: session.renaming) { _, id in
            newTitle = id.flatMap { library.recording($0)?.title } ?? ""
        }
        .onChange(of: session.expanded) { _, id in
            guard let id, let recording = library.recording(id) else { return }
            player.load(recording, url: library.url(for: recording), peaks: library.peaks[id] ?? [])
        }
    }

    private var searchPrompt: String {
        library.recordings.contains { $0.transcript != nil } ? String(localized: "Titles, Transcripts") : String(localized: "Search")
    }

    private var selectionBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.accentColor)
            .padding(.horizontal, 10)
    }

    private func toggle(_ recording: Recording) {
        guard !editMode.isEditing else { return }
        if isSplit {
            guard session.selected != recording.id else { return }
            player.pause()
            session.selected = recording.id
            player.load(recording, url: library.url(for: recording), peaks: library.peaks[recording.id] ?? [])
            return
        }
        if session.expanded == recording.id {
            session.expanded = nil
            player.pause()
        } else {
            player.pause()
            session.expanded = recording.id
        }
    }

    @ViewBuilder
    private func trailingActions(_ recording: Recording) -> some View {
        if scope == .deleted {
            Button(role: .destructive) { library.erase([recording.id]) } label: { Label("Delete", systemImage: "trash") }
            Button { library.recover([recording.id]) } label: { Label("Recover", systemImage: "arrow.uturn.backward") }
                .tint(.blue)
        } else {
            Button(role: .destructive) { trash(recording) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func trash(_ recording: Recording) {
        if session.expanded == recording.id {
            player.unload()
            session.expanded = nil
        }
        library.trash([recording.id])
    }
}

private struct SearchOnDemand: ViewModifier {
    @Binding var query: String
    @Binding var isSearching: Bool
    let prompt: String

    func body(content: Content) -> some View {
        if isSearching || !query.isEmpty {
            content
                .searchable(text: $query, isPresented: $isSearching, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(prompt))
        } else {
            content
        }
    }
}
