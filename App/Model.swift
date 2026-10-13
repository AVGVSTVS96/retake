import MemoKit
import SwiftUI

@MainActor
final class Model {
    static let shared = Model()

    let library: Library
    let recorder: Recorder
    let player = Player()
    let session = Session()
    let places = LocationNamer()

    private init() {
        library = Demo.isEnabled ? Demo.library() : Library.standard()
        recorder = Recorder(library: library, input: Demo.isEnabled ? SyntheticInput() : MicInput())
        RecordingIntentHandler.record = { [recorder, player, places] in
            player.pause()
            await recorder.record(title: places.place)
        }
        RecordingIntentHandler.stop = { [recorder, session, player, library] in
            if let recording = recorder.stop() { session.expand(recording, player: player, library: library) }
        }
    }
}
