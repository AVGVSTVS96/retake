# retake launch

The X post, a thread variant, alt text, the first reply, and captions for standalone images. Bassim's voice: lowercase, plain, sure of the work. The link goes in the first reply. Every line traces to `MESSAGING.md` and its Numbers table.

Before posting: the repo is public, the Duo shots are reshot, and retake's own ms are re-measured (see MESSAGING Numbers). Nothing below quotes retake's ms, so the post works either way.

## The post

*(Attach the stop clip: record, stop, record again, 8 to 12 s, from `testRecordStopRecordAgain.mov`, phone-cropped.)*

```
ios 27 voice memos is pretty until you stop a recording and start a new one

so i rebuilt it in swiftui. same screens, same gestures, same animations, frame-counted against ios 27 footage

> audio hits the disk as you record. app dies, next launch puts the take back
> stop closes the file instantly. no "saving…" to get stuck on
> a call or siri pauses the take, never ends it
> a test records, stops and starts again 300 times. every take is there

it's called retake. mit, iphone, ipad and iphone duo

link in replies
```

*(Bassim OKd quoting him, Oct 10. Approved line: `it looks good. but do anything complicated with it and it probably breaks.`)*

Alt text: A phone screen recording of retake. Tapping the red record button raises a recording card with a live red waveform. Tapping stop collapses the card back into the button, and "New Recording" appears at the top of the list. It repeats three times.

## First reply

```
github.com/AVGVSTVS96/retake

build it with xcode 27: `xcodegen generate`, open, run. launch with -demo for a sample library and a fake mic

not yet: layered recordings, spatial audio, icloud sync, watch
```

## Thread variant

Four posts. The first is the post above without "link in replies".

**2. The stop**

*(Attach the timing strip image.)*

```
the moment that matters is stop

voice memos shows ~330 ms of nothing after you tap it (the file finalizing), then collapses. retake closes the file right then and the row is in the list before the sheet finishes moving. aac compression runs after, in the background

frame-counted at 60 fps, ios 26 screen recording. ios 27 collapses the same way
```

Alt text: Two timing bars. Voice Memos: a gray gap of about 330 milliseconds after stop, then a 215 millisecond collapse. retake: the collapse starts right away.

**3. The bugs**

```
these are real threads on apple community:

> recordings stuck on "saving changes…" (17 me too)
> leave the app mid recording, lose the last minutes (90)
> lock screen recording stops after seconds while the dynamic island says it's still going (109)

retake writes every take to disk as it records, and every surface reads one recorder state
```

*(No image. Links to the three threads go in a reply under this one if anyone asks; they're in `reference/SPEC.md` section 6.)*

**4. Links**

The first reply above.

## Standalone images

Each is a separate post, at least 6 hours apart, each linking back in its first reply.

**The side-by-side** (light and dark, same screen; never Apple's footage)

```
retake in light and dark. built against ios 27 footage frame by frame, so it's the voice memos you know, minus the lost takes
```

Alt text: Two iPhone screenshots of retake's full recording screen side by side, light on the left, dark on the right, each with a red waveform, a running timer and a red pause button.

**The stop timing**

```
tap stop in voice memos (ios 26 screen recording) and nothing happens for ~330 ms while it saves. in retake the file is already closed. frame-counted at 60 fps
```

Alt text: A timing diagram of the stop moment. Voice Memos waits about 330 milliseconds before its 215 millisecond collapse; retake collapses right away.

**The Duo** *(after the reshoot)*

```
retake on iphone duo: the cover screen and the open book, plus ipad's split view
```

Alt text: retake on iPhone Duo, closed on the cover screen and open across both halves, showing the All Recordings list with a red record button.

## Notes

- Problem before name, per the style guide: the post leads with what breaks, and "retake" appears near the end.
- "pretty until you stop a recording" is a paraphrase of Bassim's voice note, not a quote. The quoted version is in the comment above for his yes.
- Don't claim retake fixes the Lock Screen bug outright: the code shows one state feeding the Live Activity, but no test of a Lock Screen start exists yet.
