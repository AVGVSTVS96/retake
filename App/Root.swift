import MemoKit
import SwiftUI

struct Root: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var session = Session()

    var body: some View {
        Group {
            if sizeClass == .regular {
                SplitRoot()
            } else {
                PhoneRoot()
            }
        }
        .environment(session)
    }
}

struct PhoneRoot: View {
    @Environment(Session.self) private var session
    @Environment(Recorder.self) private var recorder
    @Environment(Library.self) private var library
    @State private var path: [Scope] = [.all]
    @Namespace private var transition

    var body: some View {
        @Bindable var session = session
        NavigationStack(path: $path) {
            FoldersView()
                .listStyle(.insetGrouped)
                .navigationDestination(for: Scope.self) { RecordingsList(scope: $0) }
        }
        .overlay(alignment: .bottom) {
            if let scope = path.last, scope != .deleted {
                RecordButton()
                    .matchedTransitionSource(id: TransitionID.record, in: transition)
                    .padding(.bottom, 6)
                    .transition(.opacity)
            }
        }
        .task { await Demo.stage(session: session, recorder: recorder, library: library, path: $path) }
        .sheet(item: $session.sheet) { mode in
            RecordSheet(mode: mode)
                .navigationTransition(.zoom(sourceID: TransitionID.record, in: transition))
        }
    }
}

enum TransitionID: Hashable {
    case record
}
