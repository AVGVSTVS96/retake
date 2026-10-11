# retake · brief

## The product

retake is an MIT-licensed, open-source rebuild of Apple's iOS 27 Voice Memos in SwiftUI, by Bassim (github.com/AVGVSTVS96). Same screens, same gestures, same animations as Apple's app, on iPhone (18 Pro Max, 17 Pro Max, 15), iPhone Duo (Apple's new book-style foldable, cover + open) and iPad (11" and 13"). Without the bugs.

The code and README: `~/Developer/voice-memos` (read `README.md`, `reference/SPEC.md` for Apple's app frame by frame, `Packages/MemoKit/Sources` for the engine). Real screenshots of retake, light and dark, every device and state: `~/Developer/voice-memos/shots/raw/` (`<device>-<scene>-<light|dark>.png`; scenes: list, expanded, recording (card), recording-full, paused, player, options, transcript, trim, folders). Motion captures of the real app: `~/Developer/voice-memos/shots/motion/*.mov`.

Apple's own reference material (never put on our page; for understanding only): `~/Developer/voice-memos/reference/`.

## Why the name

A retake is recording it again. Stopping and starting a new recording is exactly where Voice Memos falls apart, and retake is a second take on Voice Memos itself. Say this once, plainly. Always lowercase.

## Bassim's words (voice transcript, verbatim, keep his intent; the bracketed bits are the transcript's)

> Hey, so I'm just realizing that this iOS, iOS 27, these Apple guys and Steve Jobs's company. Shame he's gone. I don't think he'd let this slide, but look, the voice memos app, it's kind of pretty. Like, it's got a good look to it until you use it for anything more than recording. And then stopping recording and then starting a new one, because as soon as you do that, you'll realize that this fucking app is one of the most buggy apps on iOS. Now look, hex. All right, let me be straight with you. I don't think I'm a narcissist. I don't think I'm arrogant when I say that you and I can build shit better than these fucking companies. Okay, in our sleep, like we. No effort. It takes me no effort to tell you this prompt, and it takes you no effort to go back to all the information you have access to and give me exactly what you know I want.

> So this is your deliverable: a complete MIT licensed open source perfect visual parity and perfect interaction parity and animation parity and all the parities in the world [...] with iOS 27 voice memo app [...] Finish. In addition, when you're done with this task, give me a complete GitHub repository and then run the new brand-it skill to brand it, bro. Like, build the website, fine-tune the copy based on absolutely everything that you know about me. Create a bunch of great little brand assets and photos and shit, open graph photos, photos and shit that I could use on X. Copy really nice, like I said. I'm just following really high standards for this.

## What's true (check every claim against the code)

- Audio streams to a crash-safe CAF file while recording; on launch, orphaned takes are recovered (`Library.recoverOrphans`).
- Stop closes the file synchronously (milliseconds); the recording is in the list before the sheet finishes collapsing. AAC compression happens after, in the background; playback works meanwhile.
- One recorder state machine (idle / recording / paused). Timer and waveform come from audio frames written, never a wall clock.
- Interruptions (calls, Siri) pause and keep the take.
- Test: record → stop → new take 300 times in a row, every take present with sample-exact length. A UI test does record/stop/record through the real app.
- Measured at 60fps against Apple's iOS 27 footage: tap record → card ~280ms in iOS 27, ~220ms in retake, neither overshoots. Stop → row: Apple waits ~330ms "saving" then collapses ~215ms; retake collapses in ~180ms with no wait.
- Bugs people report in Voice Memos (with links in `reference/SPEC.md` section 6): recordings stuck on "Saving changes…" (17 me-too), audio lost after switching apps mid-recording (90 me-too), Lock Screen recordings stopping after seconds while the Dynamic Island still says recording (109 me-too), recordings vanishing after Done.
- Features in: see README "What's in". Not yet: layered recordings, Spatial Audio, Studio Sound, iCloud sync, Watch.
- ~4,100 lines of Swift; engine (MemoKit) ~1,400 with 23 tests.
- Not affiliated with Apple. Never use Apple's logo, the Voice Memos icon, or Apple's screenshots on the page. Our own screenshots of retake are fine (they look like Voice Memos, that's the point).

## Who it's for and where it shows up

Bassim's X (@AVGVSTVS96), developers and designers who care about iOS craft and feel, people who've lost a voice memo. The site is the README's big sibling; the X post links it. GitHub repo AVGVSTVS96/retake (private until Bassim says public).
