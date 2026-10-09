# retake

Apple's iOS 27 Voice Memos, rebuilt in SwiftUI: same screens, same gestures, same animations. It never loses a take.

MIT. iPhone, iPad and iPhone Duo. iOS 27.

## Why

Voice Memos looks great until you use it for more than one recording. Stop, then start a new one, and people report sheets stuck on "Saving changes…", takes that vanish after Done, and audio lost when they switch apps ([links](reference/SPEC.md#6-bugs-to-design-against)). retake is the same app, built so that can't happen.

The name: a retake is recording it again, which is exactly where Voice Memos falls apart.

## What's different under the hood

- **Audio hits the disk as it records.** Each take streams to a crash-safe CAF file. If the app dies, the next launch finds the file and puts it back in the list.
- **Stop is instant.** The file closes right away and the take is in the list before the sheet finishes collapsing. Compression to AAC happens afterwards, in the background, and playback works the whole time.
- **One state machine.** Recording, paused, idle. The timer and waveform come from the audio frames actually written, not a wall clock, so they can't keep running after the audio stops.
- **Interruptions pause, they don't stop.** A call or Siri pauses the take and keeps everything recorded so far.

A test records, stops and starts a new take 300 times in a row and checks every one is there at the right length (within 30 ms after compression). A UI test does record, stop, record through the real app.

## Parity

Built against Apple's iOS 27 screenshots, the English strings from the iOS 27 simulator runtime, and 60 fps footage of the real app, frame-counted (±17 ms, from the first frame that moves; retake measured the same way from a simulator capture of `scripts/motion`):

| moment | Voice Memos | retake |
| --- | --- | --- |
| tap record → card settles | ~220 ms, no overshoot | ~215 ms, no overshoot |
| card → full sheet | follows the finger, ~200 ms after release | the system sheet, same detents |
| stop → row appears | ~330 ms save, then ~215 ms collapse* | ~190 ms collapse, no wait |

\* From iOS 26's screen recording. The iOS 27 footage doesn't film stop from the card; its Done collapse is the same ~215 ms.

What's in: the recordings list with inline player, the record card and full sheet, pause and resume, Replace from the playhead, trim and delete with Save or Save as New, playback speed, Skip Silence, Enhance Recording, on-device transcripts (live while recording, word by word while playing), folders, Favorites, Recently Deleted, search across titles and transcripts, rename, duplicate, share, the iPad split view, Live Activity and Dynamic Island, a Control Center button, and Settings (Clear Deleted, Audio Quality, Location-based Naming).

Not yet: layered recordings, Spatial Audio capture and Studio Sound (they need iPhone 16 Pro and 18 Pro mics), iCloud sync, Apple Watch.

## Build

```sh
brew install xcodegen
xcodegen generate
open VoiceMemos.xcodeproj
```

Xcode 27 builds for iPhone and iPad; the iPhone Duo simulator needs Xcode 27.1.

`MemoKit` (in `Packages/MemoKit`) is the engine: recorder, library, playback, editing and transcription, about 1,400 lines with 23 tests. Run them on the simulator with `xcodebuild test -scheme MemoKit`. `App/` is the SwiftUI. Launch with `-demo` for a sample library and a fake microphone.

## License

MIT. Not affiliated with Apple. Voice Memos is a trademark of Apple Inc.
