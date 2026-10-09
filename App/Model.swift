import MemoKit
import SwiftUI

@MainActor
final class Model {
    static let shared = Model()

    let library: Library
    let recorder: Recorder
    let player = Player()
    let session = Session()

    private init() {
        library = Demo.isEnabled ? Demo.library() : Library.standard()
        recorder = Recorder(library: library, input: Demo.isEnabled ? SyntheticInput() : MicInput())
        RecordingIntentHandler.record = { [recorder, player] in
            player.pause()
            await recorder.record()
        }
        RecordingIntentHandler.stop = { [recorder, session] in
            session.expanded = recorder.stop()?.id ?? session.expanded
        }
    }
}
