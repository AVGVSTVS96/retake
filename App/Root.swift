import MemoKit
import SwiftUI

struct Root: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if sizeClass == .regular {
                SplitRoot()
            } else {
                PhoneRoot()
            }
        }
    }
}

struct PhoneRoot: View {
    @Environment(Session.self) private var session
    @Environment(Recorder.self) private var recorder
    @Environment(Library.self) private var library
    @Environment(Player.self) private var player
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
            if let scope = path.last, scope != .deleted, !session.isSelecting {
                RecordButton()
                    .matchedTransitionSource(id: TransitionID.record, in: transition)
                    .padding(.bottom, 1)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(.keyboard)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: session.isSelecting)
        .onChange(of: recorder.phase) { old, phase in
            if old == .idle, phase == .recording, recorder.replacing == nil, session.sheet == nil {
                session.expanded = nil
                session.sheet = .recorder
            } else if phase == .idle, session.sheet == .recorder {
                session.sheet = nil
            }
        }
        .task { await Demo.stage(session: session, recorder: recorder, player: player, library: library, path: $path) }
        .sheet(item: $session.sheet) { mode in
            RecordSheet(mode: mode)
                .navigationTransition(.zoom(sourceID: TransitionID.record, in: transition))
        }
    }
}

enum TransitionID: Hashable {
    case record
}
