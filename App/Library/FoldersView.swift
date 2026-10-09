import MemoKit
import SwiftUI

struct FoldersView: View {
    var selection: Binding<Scope?>?
    @Environment(Library.self) private var library
    @State private var naming = false
    @State private var name = ""

    var body: some View {
        List(selection: selection) {
            Section {
                row(.all, systemImage: "waveform")
                if library.recordings(in: .favorites).isEmpty == false {
                    row(.favorites, systemImage: "heart")
                }
                row(.deleted, systemImage: "trash")
            }
            if !library.folders.isEmpty {
                Section("My Folders") {
                    ForEach(library.folders) { folder in
                        row(.folder(folder.id), systemImage: "folder")
                            .swipeActions {
                                Button("Delete Folder", systemImage: "trash", role: .destructive) { library.deleteFolder(folder.id) }
                            }
                    }
                }
            }
        }
        .navigationTitle("Voice Memos")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("New Folder", systemImage: "folder.badge.plus") {
                    name = ""
                    naming = true
                }
            }
        }
        .alert("New Folder", isPresented: $naming) {
            TextField("Name", text: $name)
            Button("Cancel", role: .cancel) {}
            Button("Save") { library.createFolder(named: name.trimmingCharacters(in: .whitespaces)) }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || library.folders.contains { $0.name == name })
        } message: {
            Text("Enter a name for this folder.")
        }
    }

    @ViewBuilder
    private func row(_ scope: Scope, systemImage: String) -> some View {
        let content = LabeledContent {
            Text("\(library.recordings(in: scope).count)")
        } label: {
            Label(library.title(of: scope), systemImage: systemImage)
        }
        if selection == nil {
            NavigationLink(value: scope) { content }
        } else {
            content.tag(scope)
        }
    }
}
