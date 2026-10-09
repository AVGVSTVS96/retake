# retake messaging

The source of truth for how we talk about retake. The site, the README, the OG image and the launch post all draw from here. When something here and something there disagree, fix it here first.

Every claim is checked against `~/Developer/voice-memos` (Oct 9 2026). How each number was counted is in **Numbers** at the bottom.

## One line

**retake is Apple's iOS 27 Voice Memos, rebuilt in SwiftUI, open source, and it never loses a take.**

Shorter, for a bio, a card or the repo description: **Voice Memos, rebuilt. It never loses a take.**

## Hero

The shortest part of the page.

- **Headline:** Voice Memos, rebuilt. It never loses a take.
- **Sub line:** Same screens, gestures and animations as iOS 27. Open source, in SwiftUI.
- **Buttons:** View on GitHub · Build it
- **Visual:** the real app in motion: tap record, the card rises, stop, the new row is already there. Cut from `shots/motion/testRecordStopRecordAgain.mov`, one round, looped once per scroll into view. In dark, `iphone-18-pro-max-recording-full-dark.png` as the still.

## A note from bassim (needs his yes)

One quoted line of his, verbatim from the voice note, lowercase, signed. It sits under the hero, before the sections.

> "it's got a good look to it until you use it for anything more than recording."
>
> bassim

It's his attitude without the profanity, and it says the whole problem in one breath. If he'd rather have his sharper line, it goes in the X post only, never on the page: "this fucking app is one of the most buggy apps on iOS."

## Sections

One headline, one short line, one visual each. In this order: the edge first, then parity, then reach.

### 1. Stop is instant.

**Line:** The file closes the moment you tap stop, and the take is in the list before the sheet finishes collapsing. There's no "Saving…" to get stuck on.¹

**Visual:** the stop moment from `testRecordStopRecordAgain.mov`: stop tapped, sheet collapses into the record button, new row at the top. Under it, a two-row timing strip drawn in the brand: Voice Memos, ~330 ms of nothing, then the collapse; retake, the collapse right away.¹

### 2. Every take hits the disk as you record.

**Line:** If the app dies mid-recording, the next launch finds the file and puts it back in your list. A call or Siri pauses the take and keeps everything so far.

**Visual:** `iphone-18-pro-max-paused-light.png` (dark: `iphone-18-pro-max-recording-full-dark.png`).

### 3. 300 takes in a row.

**Line:** A test records, stops and starts again 300 times, and checks every take is there at the right length.² A UI test does the same through the real app.

**Visual:** the list, `iphone-18-pro-max-list-light.png` / `-dark.png`. Optional brand-built ledger beside it: `New Recording`, `New Recording 2` … `New Recording 300`, the titles the test really produces.

### 4. Frame for frame with iOS 27.

**Line:** Built against 60 fps footage of the real app, frame-counted, plus Apple's own iOS 27 strings. Tap record and the card rises with no overshoot, like Apple's.³

**Visual:** `iphone-18-pro-max-recording-light.png` (the card) beside `iphone-18-pro-max-expanded-light.png`, or `testExpandSheetPauseResumeDone.mov`. Never Apple's footage or screenshots on the page.

### 5. The rest of the app, screen for screen.

**Line:** Trim, Replace from the playhead, transcripts that write themselves while you record.

**Visual:** a strip of real screens: `trim`, `transcript`, `options`, `player`, `folders` (18 Pro Max, light, dark where it exists). The screens carry the list so the line doesn't have to.

### 6. iPhone, iPad and iPhone Duo.

**Line:** The iPad gets the split view. The Duo gets both screens, closed and open.

**Visual:** `ipad-pro-13-list-light.png` and the two Duo shots. *(Blocked: `iphone-duo-2-list-light.png` is solid black and `iphone-duo-1-list-light.png` has the status bar and toolbar laid out beside the list. Reshoot both before this section ships; until then, the iPad alone.)*

## The name

Once, plainly, near the bottom or in the footer area. Never in a headline.

> A retake is recording it again. That's exactly where Voice Memos falls apart, so it's what this one is built around.

Always lowercase, even at the start of a sentence and in caps-styled labels. Never "Retake", "ReTake" or "RETAKE".

## What's in, what's not yet

Said plainly, in one block, near the end.

- **In:** the list with its inline player, the record card and full sheet, pause and resume, Replace from the playhead, trim and delete with Save or Save as New, playback speed, Skip Silence, Enhance Recording, on-device transcripts (live while recording), folders, Favorites, Recently Deleted, search across titles and transcripts, rename, duplicate, share, the iPad split view, Live Activity and Dynamic Island, a Control Center button, and Settings.
- **Not yet:** layered recordings, Spatial Audio and Studio Sound (they need iPhone 16 Pro and 18 Pro mics), iCloud sync, Apple Watch.

## Build

There's no App Store build. One line on the page, then the commands:

> Build it yourself. You need Xcode 27 (27.1 for the iPhone Duo simulator).

```sh
brew install xcodegen
xcodegen generate
open VoiceMemos.xcodeproj
```

Launch with `-demo` for a sample library and a fake microphone.

## Footer

retake · MIT · by bassim (@AVGVSTVS96) · Not affiliated with Apple. Voice Memos is a trademark of Apple Inc.

## Voice

Bassim's attitude: blunt, sure of the work, a craftsman showing what he made. Not an ad.

**Do**

- Say what the code does: "the file closes", "the take is in the list", "a call pauses the take".
- Put the number next to what it measures, and footnote how.
- Name Voice Memos and iOS 27 plainly. It's a rebuild and it says so.
- Let the screenshots show that it looks right. Words go to what you can't see: stop, the disk, the 300 takes.
- Sentence case on the site. Lowercase in posts in Bassim's own voice.

**Don't**

- No feature lists in sections. Section 5 is the only place features appear, and the screens carry them.
- No "pixel-perfect", "identical", "100% parity". Say what was measured.
- No "bug-free", "never crashes", "bulletproof". Say "never loses a take" and back it with the disk, the recovery and the 300.
- No fear and no mockery of Apple's team. The bug reports are real and linked; quote their counts, not adjectives.
- None of the hype words banned in the brand-it skill.
- No Apple logo, no Voice Memos icon, no Apple screenshots or footage.

| Don't | Do |
| --- | --- |
| Voice Memos, but finally done right. | Voice Memos, rebuilt. It never loses a take. |
| Lightning-fast saves. | The file closes the moment you tap stop. |
| Pixel-perfect parity with iOS 27. | Built against 60 fps footage of iOS 27, frame-counted. |
| Bulletproof recording engine. | Every take hits the disk as you record. |
| Apple's buggy app vs ours. | 109 people report Lock Screen recordings stopping after a few seconds. |

## Numbers

| Claim | Source and how it was counted |
| --- | --- |
| ~330 ms of nothing after stop, then ~215 ms collapse | `reference/SPEC.md` 4.5, frame-counted at 60 fps (±17 ms). **This is iOS 26's screen recording**: the iOS 27 footage never films stop from the card (SPEC 7). iOS 27's Done collapse is the same ~215 ms. |
| retake has no wait after stop | Code: `Recorder.stop()` closes the file synchronously (`TakeWriter.finish()`), inserts the row, then returns. AAC compression runs after, in a background task (`Library.finalize`). |
| card rises with no overshoot, ~280 ms in iOS 27 | SPEC 4.1 (touch to settle 270 to 300 ms; the card body alone ~220 ms). |
| retake card ~220 ms, stop collapse ~180 ms | README. **Not re-measured**: no measurement file in the repo. A rough read of the simulator capture (`testRecordStopRecordAgain.mov`, variable frame rate) gives ~220 ms for the card and ~245 ms from stop to a settled row. Re-measure at 60 fps before quoting retake's own ms anywhere. |
| 300 takes, right length | `RecorderTests.hammeringRecordStopNeverLosesATake`: 300 cycles, every 5th with a pause; every id and title present; file length within 30 ms of the recorded length after AAC compression. |
| ~4,100 lines of Swift | `fd -e swift \| xargs cat \| wc -l` = 4,095 (blank lines included). Engine (MemoKit) 1,389, its tests 449. |
| 23 engine tests, 3 UI tests | `rg -c '@Test'`: Recorder 10, Transcription 10, Playback 3. `UITests/FlowTests.swift`: 3. |
| 17, 90, 109 me-too | SPEC 6, Apple Community threads, rows 4, 5, 1. |

¹ Voice Memos timing from iOS 26's screen recording, frame-counted at 60 fps. iOS 27's footage shows the same collapse after Done.
² Within 30 ms, after compression to AAC.
³ Card rise in iOS 27: ~280 ms from touch to settle, measured from 60 fps footage.
