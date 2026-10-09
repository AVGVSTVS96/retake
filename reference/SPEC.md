# Voice Memos (iOS 27) parity spec

The builder's source of truth. Each claim is tagged:

- **[C]** confirmed: seen in an Apple screenshot, Apple guide text, or measured from video frames.
- **[I]** inferred: estimated from video or images, or Apple's usual conventions. Verify on a device when possible.

Sizes are in points for a 440 × 956 pt iPhone (17/18 Pro Max class). Measurements come from the iOS 26 screen recording (1.13 px/pt, the most exact), cross-checked against the iOS 27 camera footage (~1.07 px/pt, slight perspective). The iOS 26 and 27 layouts are nearly identical (see "What changed" below), so iOS 26 screen-recording numbers apply to 27 unless noted.

---

## 1. What changed across versions

| Version | Change | Source |
|---|---|---|
| iOS 14 | Enhance Recording, folders, Favorites, smart folders (Apple Watch, Recently Deleted) | prior knowledge [I] |
| iOS 15 | Playback speed slider, Skip Silence | prior knowledge [I] |
| iOS 16.1+ | Recording shows in Dynamic Island / Live Activity | guide [C] |
| iOS 18.0 | Transcription (iPhone 12+, live while recording and after), transcript search, Copy/View Transcript | guide 18 [C] |
| iOS 18.1 | Apple Intelligence Writing Tools can summarize transcripts (no native "Summary" UI in Voice Memos) | guide [C] |
| iOS 18.2 | Layered Recording (vocal over instrumental, iPhone 16 Pro+), layer 1/2 selector, Layer Mix, Separate Layers | Newsroom [C] |
| **iOS 26** | **Liquid Glass redesign**: glass circle nav buttons, glass bottom bar, record button morphs into a floating glass card. **Recording Mode** setting (Mono / Stereo / Spatial Audio; Spatial is the default on supported iPhones, saved as .qta with an APAC track). **Studio Voice** playback option (Spatial only). Control Center mic modes (Voice Isolation / Wide Spectrum). **Share/Export Options: Rendered vs Editable**. "Edit" above the list became **Select**. Playback options Close → Done ✓. Siri tip banner "Say 'Record Voice Memo'" at the top of the list. Enhance Recording / Skip Silence limited to Mono and Stereo recordings | guide 26 diff vs 18 [C], Apple Artists page [C] |
| **iOS 27** | **Studio Voice renamed Studio Sound**: adjusts background sound and reverb, recognizes music, isolates music properly only on iPhone 18 Pro recordings. Options sheet: Studio Sound row with subtitle "This applies to Layer 1 of a multilayered recording." and a 0–100 slider. List toolbar order flipped to **[Select] [Search]** (iOS 26: [Search] [Select]). Siri tip banner gone. Guide says "Tap the Search button" for transcript search (iOS 26: "swipe down"). The rename page still says swipe down, so search is likely both. Landscape layout added (BetaWiki via search summary, **unverified**). Glyph alt text "Stop Recording Video" → "Stop" (cosmetic) | guide 27 diff vs 26 [C]; Studio Sound seen in the iOS 27.0 video [C]; iOS 27 *beta* still said "Studio Voice" (Robles footage) [C] |

**Not found in iOS 27:** no native AI summary or title generation inside Voice Memos (only system Writing Tools), and no new recording UI. Motion is essentially the iOS 26 Liquid Glass set.

---

## 2. Global visual language

### Colors

| Token | Light | Dark | Notes |
|---|---|---|---|
| Record / stop red | ≈ #FF2C34 (measured), use `Color(.systemRed)` | systemRed dark | [C] measured, [I] token |
| Waveform, recording (past bars) | red, ~60–80% opacity | same | [C] |
| Waveform, idle/paused/playback | `secondaryLabel` gray bars | light gray bars | [C] |
| Playhead, recording | red 1pt line with 5pt dots at top and bottom | same | [C] |
| Playhead, paused/playback | blue (tint) 1pt line with end dots | blue | [C] |
| Waveform background band (expanded sheet) | slightly darker than the sheet, ≈ systemGray6 | ≈ #2A2A2E | [C] visible band, [I] value |
| Trim selection | yellow (systemYellow) handles, 25% yellow fill | yellow ~40% | [C] |
| Accent / tint | systemBlue (Done ✓ fill, "…" glyph, waveform button, trash, transcript selected) | systemBlue | [C] |
| List background | white (#FDFDFD measured) | black | [C] |
| Dim behind the recording card | black at ~24% (white → #C3C3C3) | black ~40% [I] | [C] measured light |
| Collapsed card fill | #EDECF5 (glass, cool light gray) | dark glass ≈ #1C1C1E | [C] light, [I] dark |
| Stop button disc | #F6F5FA glass circle | dark glass | [C] |
| RESUME capsule | red-tinted glass (~15% red over white), label red | [I] | [C] light |
| REPLACE capsule | solid red fill, white label | solid red | [C] |
| Separators | `separator` hairline, inset 20pt left/right | | [C] |
| Secondary text (dates, durations) | `secondaryLabel` | | [C] |

### Typography (SF Pro) [I], from relative sizes in measured frames

| Element | Style |
|---|---|
| "All Recordings" / "Voice Memos" / "Recently Deleted" / "1 Selected" | Large Title, 34 bold |
| Row title | 17 semibold (iOS 26/27 looks semibold; iOS 18 was regular-ish 17) |
| Row date and duration | 15 regular, secondaryLabel, duration right-aligned on the date line |
| Collapsed card title "New Recording" | 17 semibold, centered |
| Collapsed card timer "00:01.87" | 13–15 regular, monospaced digits, secondaryLabel |
| Expanded sheet title | 17 semibold (tap to rename, inline keyboard) |
| Expanded sheet subtitle "9:57 AM  0:08" | 13–15 semibold secondary; time and duration separated by ~8pt |
| Big timer "00:08.34" | ~34 semibold, monospaced digits (`.monospacedDigit()`) |
| Waveform time ruler "0:07  0:08" | 11 regular, tertiaryLabel |
| RESUME / REPLACE labels | 13 semibold, **uppercase** |
| Menu items | 17 regular; long labels wrap ("Copy Tran-/script", "View Tran-/script", "Separate/Layers") because the menu is narrow |
| Empty state | "No Recordings" 20 semibold; "Tap the Record button to start a Voice Memo" 15 regular secondary, centered, 2 lines |

### Materials (Liquid Glass) [C]

- Nav buttons are 44pt glass circles (back ‹, search 🔍) and a glass capsule ("Select", ~80 × 44).
- The bottom bar of the expanded sheet has a 36–40pt glass circle on the left (transcript), a wide capsule in the center (~160 × 50: pause, RESUME, or REPLACE), and a glass circle on the right (options).
- The top of the expanded sheet has a glass "…" circle on the left and a **blue filled circle with a white ✓** on the right (Done), both ~44pt.
- The collapsed recording card is a floating glass panel with an ~8pt inset from the screen edges on all three sides and a large corner radius concentric with the display (~40pt).
- Menus are glass popovers that grow out of their button.
- There is a scroll-edge fade at the bottom of the list behind the record button: the last row fades to transparent.
- The record button is a ~51pt red disc with a soft white glass halo or shadow ring (iOS 26 screen recording). iOS 27 footage shows a ~49–52pt disc with a subtle halo.

---

## 3. Screens

### 3.1 Recordings list, "All Recordings" (iPhone) [C]

Shots: `shots/iphone-ios27-list-row-expanded-playback-light_apple-guide.png`, `video-stills/iphone-ios26-screenrec-list-row-expanded-new_light.png`, `video-stills/iphone18promax-ios27-list-empty-state_light.png`, `video-stills/iphone-ios27beta-list-row-expanded_dark_camera.png`

```
 status bar
 (‹)                          [Select] (🔍)     ← iOS 27 order; iOS 26 was (🔍)[Select]
 All Recordings                                  ← Large Title, collapses on scroll [I]
 ─────────────────────────────────────────
 ABC song                              •••       ← selected row expands in place
 9:41 AM  💬                                     ← 💬 = has transcript; ≋ layers icon if layered
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━       ← scrubber track, 4pt, gray; filled part black
 0:00                                  −0:13
 |||‖        ⟲15     ▶     15⟳           🗑      ← waveform btn (blue) | skip −15 | play | skip +15 | trash (blue)
 ─────────────────────────────────────────
 The dog snoring
 8:32 AM                                0:07
 ─────────────────────────────────────────
 …
                    ( ● )                        ← record button, floating, centered
```

- Margins are 20pt left and right. Separators run between rows and above the first row.
- A collapsed row is ~64pt tall: title on line 1, date and icons on line 2, with the duration right-aligned on line 2.
- The expanded (selected) row is ~196pt. Under the title it has a "…" (blue, top-right, vertically centered on the title block), a scrubber with elapsed and remaining times (remaining is negative, "−0:13"), and a control row: blue waveform icon (opens the full player), ⟲15, ▶ (~28pt black), 15⟳, blue trash.
- Dates show the time of day for today ("9:41 AM"), "Yesterday", the weekday within the last week ("Wednesday", seen on iPad), and "March 26, 2026" or "Feb 7, 2026" when older. The format is locale-driven [C].
- Default names are "New Recording", "New Recording 2", "New Recording 3"… or the location name when Location Services is on [C].
- The record button is ~51pt, centered, with its center ~64pt above the bottom of the screen. It shows only on recording lists, not on the folders screen [C].
- Empty state: an outline folder SF Symbol (~48pt, secondary), then "No Recordings", then "Tap the Record button to start a Voice Memo". The Select button is disabled (dimmed) [C].
- iOS 26 only: a Siri tip banner under the title, "Say 'Record Voice Memo'", ~35pt tall, rounded 8, quaternary fill, Siri orb icon, ✕ close [C].
- Swipe actions: none confirmed in footage [I]. Expect standard trailing Delete.

### 3.2 Row "…" menu [C]

Shots: `video-stills/iphone18promax-ios27-row-more-menu-top_light.png`, `…-scrolled_light.png`, `iphone-ios27beta-row-more-menu-studio-voice_dark_camera.png`

The menu is a glass popover anchored to the "…" and scrollable. It has grouped sections:

1. Share
2. Rename · Edit Recording · View Transcript · Copy Transcript · Separate Layers (only for layered recordings)
3. Options · ✓ Studio Sound (toggle with checkmark, Spatial recordings only; "Studio Voice" in iOS 26)
4. Favorite · Duplicate · Move

Each item has a leading SF Symbol: square.and.arrow.up, pencil, waveform, quote.bubble, text.quote, square.2.layers.3d, slider.horizontal.3, waveform.badge…, heart, plus.square.on.square, folder [I symbol names]. Delete is not in this menu; it's the trash button in the expanded row [C].

### 3.3 Recording: collapsed card (bottom sheet, detent 1) [C]

Shots: `video-stills/iphone-ios26-screenrec-recording-card-collapsed_light.png`, `video-stills/iphone18promax-ios27-recording-card-collapsed_light.png`, `video-stills/iphone18pro-ios27-recording-card-collapsed-over-list_light.png`

```
 ┌───────────────────────────────────────┐   ← inset ~8pt left/right/bottom, top ~y 634pt
 │                 ───                   │   ← grabber 36 × 4
 │           New Recording 3             │   ← 17 semibold
 │              00:02.23                 │   ← timer, secondary, monospaced
 │                                       │
 │  ··············|||‖|‖‖‖|||‖‖|‖‖|‖‖|   │   ← live waveform, newest bar at the right edge,
 │                                       │     scrolls left; dotted center line ahead of it
 │                 (■)                   │   ← stop: 58pt glass disc, 22pt red rounded square
 └───────────────────────────────────────┘
```

- The card is ~313pt tall (iOS 26 measurement). In iOS 27 on a 18 Pro Max it looks the same.
- The list behind is dimmed (~24% black) and non-interactive. Nav bar items stay visible but dimmed [C].
- Swipe up or tap the card to expand to the full sheet (the guide says "swipe up from the top of the waveform") [C].
- The Dynamic Island shows the live waveform on the left and a red timer on the right (`iphone-ios27-dynamic-island-recording-light_apple-guide.png`). The orange mic privacy dot is drawn by the system [C].

### 3.4 Recording: expanded sheet (detent 2, full height) [C]

Shots: `shots/iphone-ios27-recording-sheet-expanded-light_apple-guide.png`, `video-stills/iphone18promax-ios27-recording-sheet-expanded_light.png`, `…-paused-resume_light.png`, `…-replace-mode_light.png`, `…-transcript-view_light.png`

```
 ┌──────────────────────────────────────────┐   ← sheet, top ~y 62, grabber
 │ (…)                                 (✓)  │   ← glass "…" | blue filled Done
 │               ABC Song                    │
 │            9:41 AM   0:07                 │
 │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓●▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│   ← waveform band ~300pt tall, full width
 │ ‖|‖‖|‖‖|‖|‖‖‖|‖‖|‖‖|│                    │     playhead fixed at center x;
 │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓●▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓(+)│     (+) add layer, blue, bottom-right when paused
 │ :05     :06     :07     :08               │   ← time ruler with minor ticks
 │                                          │
 │              00:07.00                    │   ← big timer
 │          ⟲15     ▶     15⟳              │   ← gray/disabled while recording
 │ (💬)        [   ❚❚   ]            (≡)   │   ← transcript | pause capsule | options
 └──────────────────────────────────────────┘
```

States of the center capsule:

| State | Capsule | Waveform and playhead | Transport |
|---|---|---|---|
| Recording | glass capsule, red ❚❚ | red bars, red playhead | disabled gray |
| Paused (fresh recording) | pink glass capsule, red "RESUME" | gray bars, blue playhead, (+) visible | enabled black |
| Existing recording opened | solid red "REPLACE" capsule (with layer badge ① or ② on layered recordings) | gray bars, blue playhead | enabled |
| Replacing | ❚❚ again; waveform turns red where it's being overwritten | | |

- On pause, the displayed time snaps back a bit (12.14 → 11.98 in footage). The last buffer isn't counted, so the timer jumps to the committed length [C, frame-observed].
- Transcript toggle: the waveform crossfades into a transcript paragraph (~17–20pt regular, left-aligned, 20pt margins, current word **bold**). The 💬 button becomes filled blue. Text is selectable (Copy, Select All) [C].
- The sheet "…" menu has Undo, Copy Transcript, Trim, and Separate Layers [C].
- Done (✓) saves and dismisses back into the record button (see animations). "Done" was a text button in iOS 18 [C].
- Layer selector: a "1 | 2" segmented glass pill at the bottom-right of the waveform band. The record button shows a "2" badge when recording layer 2 [C] (`iphone-ios27-layer2-record-light_apple-guide.png`).

### 3.5 Full player / edit (existing recording) [C]

This is the same sheet as 3.4, opened from the row's blue waveform button. It shows REPLACE in the center.

Trim mode (`iphone-ios27-edit-trim-light_apple-guide.png`):
- Top bar: (✕) on the left, an empty glass circle on the right (Apply/✓ enabled once there's a change).
- The main waveform has a yellow-tinted selection with a yellow playhead.
- Below it is a mini overview waveform (~40pt tall) with yellow trim handles (‹ ›) and a blue position marker.
- Big timer, then transport.
- Bottom: on the left a "trim to selection" glass button (film-strip-with-arrows glyph); on the right a red trash in a glass circle (delete the selection).
- Apply → Done → choose "Save Recording" or "Save as New Recording" [C guide].
- iPad: the transport is on the left, the trim/delete pair sits in a center capsule, the big timer is on the right, and the overview strip is full width [C].

### 3.6 Options sheet (playback options) [C]

Shots: `video-stills/iphone18promax-ios27-options-sheet-studio-sound-{off,on}_light.png`, iOS 18 dark: `iphone-ios18-dark-playback-options-sheet_screenrec-in-mockup.png`

The options panel replaces the sheet contents (it grows out of the ≡ button):

```
 (↺)            Options              (✓)      ← reset | title | Done (blue)
 Playback Speed
 [ 🐢 ─────────■─────────── 🐇 ]               ← stepped slider, 1× in the middle, tick marks
 [ Studio Sound                    (◯━) ]      ← toggle
 [ This applies to Layer 1 of a              ]
 [ multilayered recording.                   ]
 [ ──────────●──────────────────── 50 ]        ← strength 0–100, value at right (shown when on)
 Layer Mix                                      ← layered recordings only
 [ ① ───────────●────────────── ② ]
```

Mono/Stereo recordings show **Skip Silence** and **Enhance Recording** toggles instead of Studio Sound [C guide]. In iOS 18 the panel had "PLAYBACK SPEED" as an uppercase section header and Reset as a text button [C].

### 3.7 Folders screen, "Voice Memos" [C]

Shot: `video-stills/iphone18promax-ios27-folders-list_light.png`

- Reached with ‹ from All Recordings.
- Toolbar on the right: a new-folder glyph (folder.badge.plus) in glass, and "Edit" (disabled when there are no user folders).
- Large title "Voice Memos".
- An inset grouped list: "All Recordings" (blue waveform icon, count, ›) and "Recently Deleted" (blue trash icon, count, ›). "Favorites" and "Watch Recordings" smart folders and user folders appear when they apply [C guide].
- No record button on this screen.

### 3.8 Recently Deleted [C]

Shots: `video-stills/iphone18promax-ios27-recently-deleted_light.png`, `…-select_light.png`

- The list looks like All Recordings. There's no record button.
- **Select** mode: the title becomes "1 Selected", the toolbar shows Cancel, rows get leading selection circles (blue ✓ when filled), and the bottom toolbar shows "Recover" (left) and "Delete" (right). With nothing selected these read "Recover All" and "Delete All" [C].
- Recordings are kept 30 days by default (Settings › Apps › Voice Memos › Clear Deleted) [C].

### 3.9 Select mode on All Recordings [I]

The title becomes "N Selected" and rows get selection circles. The bottom toolbar has Share (which contains Move to Folder) and Delete [C guide text]. Not filmed.

### 3.10 Search [C guide, not filmed]

The 🔍 button reveals a search field (pull-down also works). Search matches titles and transcript text. Selecting a transcript hit puts the playhead at that word. On iPad the field is persistent in the toolbar: "Titles, Transcripts" with a mic.

### 3.11 Share [C]

The standard share sheet has an "Options ›" chip under the file preview (`iphone-ios27beta-share-sheet_dark_camera.png`). Options shows "Send As": **Rendered** ✓ / **Editable**, with the footnote "Choose 'Rendered' to send a single file with all effects and layers mixed in. Choose 'Editable' to send a file where effects and layers can be configured by a recipient who is on a compatible device and software update." [C]

### 3.12 Settings (Settings › Apps › Voice Memos) [C guide text, no screenshot]

- Recording Mode (Mono / Stereo / Spatial Audio)
- Clear Deleted (Never / Immediately / After 1 Day / After 7 Days / After 30 Days [I options])
- Audio Quality (Compressed / Lossless [I])
- Location-based Naming [I]

### 3.13 iPad (iPadOS 27) [C]

Shots: `ipad-ipados27-*`

- A two-column split. The sidebar (~240pt) has a sidebar toggle, "Select", the large title "All Recordings", and "8 Recordings" (caption, secondary). The selected row is a **blue filled rounded rect with white text**. The record button sits at the bottom center of the sidebar.
- The detail pane has a floating glass toolbar: a cluster of [Share, Favorite ♡, Move 📁, Delete 🗑], then on the right separate glass buttons [Options ≡] [Transcript 💬] [Edit waveform], then a search field "Titles, Transcripts" with a mic.
- Detail content: title + subtitle centered, a large waveform with a blue playhead fixed at the left edge (0:00 at the start), a time ruler, a full-width overview strip with the blue position marker and 0:00 … 0:28, a big timer "00:00.00", and a glass transport capsule [⟲15 ▶ 15⟳].
- iPad has a third folder level reached via the sidebar toggle [I].

### 3.14 System surfaces

- **Dynamic Island** (compact): red waveform glyph on the left, red elapsed time "0:10" on the right [C]. Expanded/Lock Screen Live Activity: **no reference found** [gap].
- **Control Center**: "Voice Memos" mic-mode module (Voice Isolation / Wide Spectrum) [C guide]. A "Record Voice Memo" control for Control Center, Lock Screen, and the Action Button exists (iOS 18+ controls) [I, confirmed indirectly by bug reports].

---

## 4. Animations (frame-counted at 60 fps)

Timing = frames ÷ 60. ±1 frame (±17 ms) error. Folder names refer to `frames/`.

### 4.1 Tap record → card rises — the signature morph [C]

`ios27_record-tap_card-rise` (f126–f140), `ios26_screenrec_record-tap_card-rise` (f130–f147)

```
 f+0   touch down: disc dims slightly (~0.95 scale) [I]
 f+1   disc flashes white/blurs out (iOS 26), or grows ~1.3× and goes pink-translucent (27)
 f+2–4 the disc becomes a glass blob; a small red ■ appears at its center
 f+5   blob stretches into a rounded rect ~60% of the final width, still centered on the button
 f+5–16 card grows to full width and height, anchored at the bottom; contents blur in
       (title/timer appear blurred at f+6 and are sharp by ~f+10)
 f+0–8 list dim fades in to ~24% black
```

- Duration: ~16–18 frames (≈ 270–300 ms) from touch to settle. The card body itself takes ~13 frames (≈ 220 ms).
- Card top edge per frame (iOS 26, px): 868 841 815 791 772 755 743 734 733 722 719 718 717 716. That's monotonic and **no overshoot**: an ease-out, critically damped spring. Use `.spring(response: 0.3–0.35, dampingFraction: 1.0)`, or Liquid Glass `glassEffect` morphing with a shared `glassEffectID` between the record button and the card.
- The stop ■ is present from the start and stays at the button's position, so the button "becomes" the card's stop control.
- Waveform bars start streaming ~150–250 ms after the card settles [C, they appear in the following frames].

### 4.2 Collapsed card → expanded sheet [C]

`ios27_card-swipe-up_to_expanded-sheet` (drag f096–f133, release f135, settle ~f147), `ios27_tap-card_to_expanded-sheet` (tap version)

- It's interactive: the card tracks the finger 1:1 while dragging.
- During the drag the collapsed contents (title, small waveform) crossfade and blur into the expanded layout. At ~60% progress both layers are visible at once.
- After release the sheet runs to full height in ~12 frames (≈ 200 ms) with no overshoot. The title blurs during the move (material blur on the moving content).
- The stop ■ morphs into a wide glass capsule with red ❚❚ (in place at ~f+2 after release). The transcript and options glass circles fade in at the bottom corners.
- The waveform band, ruler, timer, and transport fade in. The timer keeps counting the whole time (no hitch).
- Tap-to-expand runs the same ~200–250 ms sheet animation.

### 4.3 Pause / Resume [C]

`ios27_pause-resume` (pause tap ~f108, settled ~f132; resume tap ~f192)

- Press: the capsule flashes white (glass highlight) for ~3 frames.
- Over ~10 frames (≈ 170 ms) the capsule tints pink, the ❚❚ crossfades to the "RESUME" text, the waveform bars go red → gray, the playhead goes red → blue, and the (+) fades in.
- The timer snaps to the committed length (see 3.4).
- Resume is the reverse, same duration.

### 4.4 Done → sheet collapses into the record button, row appears [C]

`ios27_done_sheet-dismiss_row-insert` (tap f104 → settle f117)

```
 f104  ✓ tapped: capsule label disappears (REPLACE → plain red capsule)
 f106  sheet content blurs
 f108  sheet scales down (~0.9) and goes translucent; list visible behind, dim fading
 f109–113 sheet shrinks toward the button position; a red fill grows inside it
       (the sheet *becomes* the red disc: gooey/metaball-looking glass morph)
 f114–116 compact red blob with a trailing ghost settles into the disc
 f117  disc at rest (≈ 1.0 scale, no visible overshoot)
```

- Duration ≈ 13 frames (≈ 215 ms). The dim fades out over the same window.
- The new or edited recording is already at the **top of the list, expanded/selected** when the list shows through (it's inserted under the sheet, not after it) [C].

### 4.5 Stop from the collapsed card (iOS 26 screen recording) [C]

`ios26_screenrec_stop_card-collapse_row-insert` (stop tap ≈ f076; collapse f096–f109)

- Tap: the stop ■ lightens (press) for a few frames, then the save completes (~20 frames ≈ 330 ms of nothing visible happening, which is the file finalizing).
- f097: the card contents clear instantly. The ■ is replaced by the red record disc at the same spot.
- f097–f100: the card shrinks downward. The disc slides down with it.
- f101–f109: a translucent glass blob carrying the red dot slides into the record-button position and condenses into the disc.
- Meanwhile (f098–f105, ≈ 120 ms) existing rows slide down one row height and the new row appears at the top, **already expanded** with scrubber and transport. The dim fades out (f100–f104).
- Total visible collapse ≈ 13 frames (≈ 215 ms). Matches 4.4.

> Design note: Apple waits for finalization *before* animating. We should do the same, driven by the recorder's "finalized" event and not a timer (see bugs below). If finalization is slow, keep the card in a "Saving…" state, not a frozen one.

### 4.6 Row waveform button → full player [C]

`ios27_row-waveform-button_to_full-player` (tap ~f075, settled ~f095)

The same morph as 4.1, but the source is the record button area: the list dims, a red-tinted glass blob grows from the bottom center into the full sheet. ≈ 15–20 frames (250–330 ms). The REPLACE capsule appears at the end.

### 4.7 Options panel open [C]

`ios27_options-sheet-open` (tap ≈ f060, settled ≈ f075)

The ≡ button morphs into the Options panel. Sheet content blurs out while the options rows blur in from the top-left. The panel grows out of the button. ≈ 15 frames (250 ms), no overshoot.

### 4.8 Menus ("…" on a row or the sheet) [C]

`ios27_row-more-menu-open` (tap ~f098, visible f105, settled ~f112), `ios27_sheet-more-menu-open`

A standard iOS 26 glass menu: it grows from the anchor button with blur → sharp, ≈ 10–12 frames (170–200 ms). There's a slight scale-up from ~0.6 [I]. No dimming of the background.

### 4.9 Transcript toggle [C]

`ios27_transcript-toggle` (tap ~f050, done ~f068)

Waveform → transcript crossfade, ≈ 15 frames (250 ms). The 💬 button fills blue at the same time. The big timer and transport stay put.

### 4.10 Delete row (trash in the expanded row) [C]

`ios27_delete-row_to-empty-state` (tap ~f110, done ~f122)

The row fades out and collapses in ≈ 10–12 frames (≈ 180 ms). Rows below slide up. The empty state fades in at the same time when it was the last row. Select goes disabled.

### 4.11 Back to folders [C]

`ios27_back-to-folders`

A standard navigation pop (~350–400 ms, system curve). The record button fades out with the outgoing page. Large titles crossfade.

### 4.12 Live waveform [C/I]

- In the collapsed card: the newest bar is drawn at the right edge, older bars scroll left, and a dotted center line continues to the right edge [C].
- In the expanded sheet: the playhead is fixed at the center, bars appear at the playhead and scroll left. The area right of the playhead is empty (dotted baseline) [C].
- Bar pitch ≈ 4.5–5pt, bar width ≈ 1.5–2pt, rounded caps, symmetric about the center line [I measured].
- Bar height is proportional to RMS/peak in dB with a floor, so silence still draws a 1pt dot [C, visible dotted baseline].
- Updates at display rate (60/120 Hz), scrolling continuously, not stepping per bar [I].

---

## 5. Exact UI copy (seen)

All Recordings · Voice Memos · Recently Deleted · Select · Cancel · Edit · N Selected · Recover · Delete · Recover All · Delete All · No Recordings · Tap the Record button to start a Voice Memo · New Recording · New Recording 2 · RESUME · REPLACE · Done · Options · Playback Speed · Studio Sound · This applies to Layer 1 of a multilayered recording. · Layer Mix · Skip Silence · Enhance Recording · Reset · Undo · Copy Transcript · View Transcript · Trim · Delete · Separate Layers · Share · Rename · Edit Recording · Favorite · Duplicate · Move · Move to Folder · New Folder · Save Recording · Save as New Recording · Apply · Send As · Rendered · Editable · Titles, Transcripts (iPad search placeholder) · 8 Recordings (iPad count) · Say "Record Voice Memo" (iOS 26 tip) · "copy" suffix on duplicates.

---

## 6. Bugs to design against

From Apple Community, AppleVis, and MacRumors (Reddit was unreachable). None are acknowledged by Apple. Counts are "Me too" totals where visible.

| # | Symptom | Versions | Signal | Links |
|---|---|---|---|---|
| 1 | Recording started from the Lock Screen / Control Center stops after a few seconds while the Dynamic Island still shows it recording | iOS 18.2.1 | 109 me-too | https://discussions.apple.com/thread/255943297 |
| 2 | Action Button "hold to record" from the Lock Screen never starts; works after unlocking | iOS 26.5.2 | snippet only | https://applevis.com/forum/ios-ipados/voice-memos-action-button |
| 3 | Error starting from the Action Button | iOS 26.3 | 1 thread | https://discussions.apple.com/thread/256253116 |
| 4 | New recordings stuck at "Saving changes…" | iOS 18 | 17 me-too | https://discussions.apple.com/thread/256026813 |
| 5 | Leave the app mid-recording: the last minutes are lost, and "…"/Share become dead so the memo can't be saved | iOS 15+ | 90 me-too | https://discussions.apple.com/thread/253902843 |
| 6 | Recording vanishes after Done, or no Done/Save after stopping | long-running | many pages | https://discussions.apple.com/thread/8542489?page=8 |
| 7 | App crashed while a long recording was saving; the audio survived only as a raw file | — | snippet | https://origin-discussions2-us-dr-prz.apple.com/thread/253472597 |
| 8 | Deleting on one device removed recordings everywhere (sync turned on by an update) | iPadOS 17 | 26 me-too | https://discussions.apple.com/thread/256035810 |
| 9 | Recordings missing after the iOS 26 update (restored from a Mac) | iOS 26 | anecdote | https://www.stellarinfo.com/blog/wp-json/wp/v2/posts/29175 |
| 10 | Grainy/distorted audio after iOS 26 (Voice Isolation mic mode left on) | iOS 26 | 38 me-too | https://discussions.apple.com/thread/256245016 |
| 11 | Recording stops when a call or notification arrives | various | snippet | https://spy.macrumors.com/threads/voice-memo-app-issue.2408753/ |
| 12 | Silent stop at a fixed length or file size (historical) | iOS 3 | — | https://discussions.apple.com/thread/2160876?page=7 |

Not found despite searching: reports specifically about stop → immediately start a new recording, a frozen waveform while audio continues, 0:00-duration files, or transcripts stuck on "Transcribing…". They may well exist on Reddit, which we couldn't reach.

**Design rules that follow:**

1. **Write audio to disk as you go.** Use AVAudioFile/AVAssetWriter in small chunks, so a crash, an app kill, or an interruption keeps everything up to that point (bugs 5, 6, 7).
2. **Make finalization crash-safe.** Record to a temp file in the library folder, finalize, then do an atomic rename. On launch, scan for orphaned temp files and recover them as "Recovered Recording" instead of dropping them.
3. **Use one recorder state machine**: `idle → arming → recording ⇄ paused → finalizing → idle`. The record button stays enabled during `finalizing` and *queues* the next start. The next session opens a new file immediately, so stop → start never blocks or loses either recording. Every UI surface (card, Dynamic Island, Live Activity, Control) renders from this one state.
4. **Drive the UI from audio engine events, never timers.** Show "recording" only after the engine reports it's running. Build the waveform from tap buffers. Take the timer from frames written, not wall clock, so the timer can never run while audio has stopped.
5. **Handle interruptions out loud.** On AVAudioSession interruptions, route changes, and media-services resets: auto-pause, keep the file, and show a paused state with a reason. Never stop silently (bugs 1, 11).
6. **Treat the local file as the source of truth.** Sync is a layer on top, and deletes are tombstones moved to Recently Deleted (bug 8).
7. **Make mic mode visible.** If Voice Isolation is active, show it. Don't let processing persist unnoticed (bug 10).
8. **No hidden length or size caps.**

---

## 7. Gaps (no reference found)

- **Dark mode on iOS 27** for the recording card, expanded sheet, options, and trim. We only have camera-filmed iOS 27 beta dark footage (list, menu, share) and iOS 18 dark screen recordings.
- **Lock Screen Live Activity and expanded Dynamic Island** while recording.
- **iPad motion**: no iPadOS 26/27 Voice Memos video. iPad specs come from the three Apple guide stills only. Landscape iPhone (new in 27, unverified) is not filmed at all.
- **Search UI**, **Select mode on All Recordings**, **Move to Folder sheet**, **Settings › Voice Memos**, **swipe actions**: text only, no images.
- **Stop → row insert on iOS 27** specifically (the iOS 27 footage uses Done ✓). The iOS 26 screen recording covers it, and the iOS 27 Done collapse matches it.
- Native-resolution iOS 27 screen recordings (all iOS 27 footage is camera-filmed with a lavender cast). Sample colors from the iOS 26 screen recording or Apple's guide images instead.
- Haptics: unknown. Expect `.impact(.medium)` on record start and stop [I].
