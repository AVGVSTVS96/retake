# retake

Apple's iOS 27 Voice Memos, rebuilt in SwiftUI: same screens, same gestures, same animations. Minus the part where it loses your recording.

MIT licensed. iPhone, iPad and iPhone Duo. iOS 27.

## Why

Voice Memos looks great until you use it for more than one recording. Stop, then start a new one, and you meet stuck "Saving…" sheets, takes that vanish after Done, and audio lost when you switch apps. This is the same app, built so that can't happen.

## What's different under the hood

- **Audio hits disk as it records.** Each take streams to a crash-safe CAF file. If the app dies, the next launch finds the file and recovers it.
- **Stop is instant.** The file closes in a few milliseconds and the recording is in the list before the sheet finishes collapsing. Compressing to AAC happens afterwards, in the background, and playback works the whole time.
- **One state machine.** Recording, paused, idle. The timer and waveform come from the audio frames actually written, never a wall clock, so they can't run while audio has stopped.
- **Interruptions pause, they don't stop.** A call or Siri pauses the take and keeps everything recorded so far.

A test records, stops and starts a new take 300 times in a row and checks every one is there with the exact length. A UI test does the same through the real app.

## Parity

Built against Apple's own iOS 27 screenshots, the English strings from the iOS 27 simulator runtime, and 60fps footage of the real app, frame-counted:

| moment | iOS 27 | here |
| --- | --- | --- |
| tap record → card | ~280 ms, no overshoot | ~220 ms, no overshoot |
| card → full sheet | follows the finger, ~200 ms after release | the system sheet, same detents |
| stop → row appears | ~330 ms save, then ~215 ms collapse | ~180 ms collapse, no wait |

What's in: the recordings list with inline player, the record card and full sheet, pause and resume, Replace from the playhead, trim and delete with Save or Save as New, playback speed, Skip Silence, Enhance Recording, on-device transcripts (live while recording, word by word while playing), folders, Favorites, Recently Deleted, search across titles and transcripts, rename, duplicate, share, the iPad split view, Live Activity and Dynamic Island, a Control Center button, and Settings (Clear Deleted, Audio Quality, Location-based Naming).

Not yet: layered recordings, Spatial Audio capture and Studio Sound (they need iPhone 16 Pro and 18 Pro mic hardware), iCloud sync, Apple Watch.

## Build

```sh
brew install xcodegen
xcodegen generate
open VoiceMemos.xcodeproj
```

Xcode 27 builds for iPhone and iPad; the iPhone Duo simulator needs Xcode 27.1.

`MemoKit` (in `Packages/MemoKit`) is the engine: recorder, library, playback, editing, transcription, all tested on the simulator with `xcodebuild test -scheme MemoKit`. `App/` is SwiftUI. Launch with `-demo` for a seeded library and a synthetic microphone.

## License

MIT. Not affiliated with Apple. Voice Memos is a trademark of Apple Inc.
