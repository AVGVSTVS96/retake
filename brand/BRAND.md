# retake · brand

**The idea in a sentence:** retake is built from the recording screen's own parts, the record button, the playhead, the waveform bars and trim's yellow, in the app's own colors, because the whole point of retake is that it looks exactly like the app it rebuilds.

Open `specimen.html` to see all of it working. `shots/` has it rendered in light and dark at every width.

## Personality

- **Sure of the work.** One person rebuilt an Apple app and says what was measured. No hype, no mockery of Apple.
- **Exact.** Numbers sit next to what they measure, with a footnote saying how.
- **Native.** It should feel like it belongs on an iPhone: Apple's grays, Apple's red, real screenshots, nothing drawn that the app doesn't have.
- **Blunt, in Bassim's words.** His quote is the one place the page has an attitude, and it's his.

| it is | it isn't |
| --- | --- |
| Voice Memos, rebuilt | a Voice Memos theme, a "better" Voice Memos |
| measured against 60 fps footage | "pixel-perfect", "100% parity" |
| a take that's always on disk | "bug-free", "bulletproof" |
| the record button, the playhead, the bars | microphones, soundwaves as decoration, Apple's icon |

## Name and voice

- **Always lowercase "retake"**, also at the start of a sentence, in titles and in the logo. Never Retake, ReTake, RETAKE.
- A retake is recording it again. That's where Voice Memos falls apart, and it's a second take on Voice Memos. Say it once, plainly, near the bottom. Never pun on it in headlines.
- The words live in `../copy/MESSAGING.md`; numbers and names in `../copy/facts.json` (rebuild with `bun copy/facts.mjs`).
- Bassim's approved line, exactly: "it looks good. but do anything complicated with it and it probably breaks." signed "bassim".
- Never Apple's logo, the Voice Memos icon, or Apple's screenshots or footage. Our own screenshots of retake are fine; they look like Voice Memos, which is the point. The footer always says "Not affiliated with Apple. Voice Memos is a trademark of Apple Inc."

## Logo

**Pick: B, Button.** The mark is Voice Memos' record button caught halfway through its morph into the stop square: the ring the app draws around it and a red shape between a disc and a rounded square (a superellipse, exponent 3). That morph is the exact moment retake was built around, record then stop then record again, and it is the one thing on the screen everyone recognizes. Beside it, "retake" in Funnel Display 700. The mark works on its own as the favicon and the app icon, and it reads at 16px as a red dot in a ring.

Three directions were drawn (`logo/explore-*.svg`, shown in the specimen):

- **A · Playhead** (`explore-a-playhead.svg`). The word cut in two by the red playhead: "re | take", the point where a new take starts. The best idea of the three in words, and it lives on as the closing visual of the site. Passed as the logo because the playhead is a 2px line: it disappears at favicon size and can't be an app icon.
- **B · Button** (`explore-b-button.svg`). Picked, above.
- **C · Waveform** (`explore-c-waveform.svg`). The word sliced into the app's bars, with a red playhead after it. Striking at 400px, mush at 32. Waveform type is also the most common audio-app cliché there is.

Construction (units of 1000 per em, from `logo/gen.mjs`):

- Letters: Funnel Display 700 (instanced from the variable font into `logo/src/`), outlined, tracking −34, the font's kerning applied.
- Mark: a circle 600 across, centered on the x-height. Ring 7% of the diameter. Gap 7.5%. Inside, a superellipse with exponent 3 at 76% of the resting disc's radius. 170 between mark and word.
- App icon: the mark at 70% of a 1024 tile, ring 5%. Light: white tile, `#D1D1D6` ring (the app's own button ring), red shape. Dark: black tile, `#48484A` ring, `#FF4245` shape. Tinted: black tile, gray ring, white shape. Written to the app's `AppIcon.appiconset` with all three appearances.

Rules:

- **Clear space:** the mark's ring diameter on every side of the lockup.
- **Smallest sizes:** lockup 20px tall, mark 16px.
- **Color pairs only:** ink ring with red shape on paper; `#F5F5F7` ring with `#FF4245` on dark. `-mono` files use `currentColor` and cut the ring and shape out of one color.
- **Never** recolor the shape anything but red, animate the ring, outline the word, or set the word in another face.

## Type

All three are under the SIL Open Font License, subset to Latin and self-hosted from `fonts/` with their licenses.

| family | file | use |
| --- | --- | --- |
| **Funnel Display** | `funnel-display.woff2` (variable 300–800) | logo, headlines, the quote |
| **Funnel Sans** | `funnel-sans.woff2` (variable 300–800) | body, UI, buttons, labels, figures |
| **Geist Mono** | `geist-mono.woff2` | code only |

The app itself is SF Pro, which can't be shipped on the web. Funnel is the distinctive choice over the safe one (Inter Display reads as SF's twin and disappears). Its cut-in joins give "retake" a voice, and Display and Sans were drawn together, with tabular figures (`tnum`) for every time and duration.

| role | family · weight | size / line | tracking |
| --- | --- | --- | --- |
| display | Display 700 | 92/94, fluid to 40 | −0.045em |
| h2 | Display 650 | 54/56 (mobile 34/36) | −0.035em |
| quote | Display 500 | 50/57 (mobile 30/34) | −0.03em, hanging open quote |
| lede | Sans 400 | 22/32 | 0 |
| body | Sans 400 | 17/26 | −0.003em |
| small | Sans 400–600 | 13–15 | 0 |
| code | Mono 400 | 14/26 | 0 |

## Color

Apple's system colors, taken from retake's own screenshots, each meaning what it means in the app. There are three accents, never one, and each has a job.

| token | light | dark | means |
| --- | --- | --- | --- |
| `--paper` | `#F2F2F7` | `#000000` | page; iOS grouped background, and the app's own black |
| `--surface` | `#FFFFFF` | `#1C1C1E` | cards, the code block, the timing chart; the app's sheet |
| `--sunk` | `#E9E9EF` | `#111113` | segmented controls, the collapse bar |
| `--ink` | `#111113` | `#F5F5F7` | text |
| `--ink-2` | `#55555B` | `#AEAEB2` | secondary text |
| `--ink-3` | `#6B6B71` (4.7:1) | `#8E8E93` (6.4:1) | captions, saved bars, the idle playhead |
| `--red` | `#FF383C` | `#FF4245` | **recording.** The live take, the mark, the one highlighted thing |
| `--red-ink` | `#D3141B` | `#FF6961` | red as text on paper |
| `--trim` | `#F5E8B5` | (yellow ink) | **selected.** Trim's tint as a band under one phrase by day; by night the phrase is set in `--yellow` |
| `--yellow` | `#FFCC00` | `#FFD60A` | trim's handles; the highlighted phrase in dark |
| `--blue` | `#0088FF` | `#0091FF` | **playing.** Focus rings |
| `--link` | `#0060C7` | `#5CB3FF` | links |
| `--bezel` | `#1D1D1F` | `#2C2C2E` | the phone frame |

- **Dark is the app's dark.** retake's dark screenshots are pure black with `#1C1C1E` sheets, so the page is black and cards are `#1C1C1E`: the screenshots sit on their own background, and each layer toward you is lighter. The bezel lifts to `#2C2C2E` so a phone reads against black.
- **Trim yellow stays light.** By day it's a pale band under the phrase. By night it moves into the ink at full strength (`#FFD60A` text, no band): the app's dark trim tint is an olive that read as mud under white text and fought GitHub's blue-black, so it isn't used on the page.
- One red thing per view. The live take, the record dot, the playhead, or retake's bar in a comparison. Never red text for emphasis.

## Grid and spacing

- **Page:** 1160px content, gutters 20–40px. Sections 96–160px apart.
- **Corners:** 10 for bars and chips, 20–24 for cards, fully round for buttons. Phones use the device's own corner radius (13.5% of width).
- **Lines:** 1px `--hair` rings instead of borders. The only shadow is under phones: `0 40px 80px -40px rgb(0 0 0 / .35)`.

## Motifs

1. **The button.** Ring plus red shape. The logo, the favicon, the app icon, the dot before Bassim's name.
2. **The playhead.** 2px with a 9px dot at each end. Red while something is recording or being explained, `--ink-3` when idle. In the hero it follows the clip; in the timing chart it sweeps at real speed; at the bottom it splits "re | take".
3. **The bars.** 2px rounded bars on a 4–5px pitch, symmetric about a center line, dotted line for silence, exactly as the app draws them. Red while live, `--ink-3` once saved. Only real data: the hero clip's takes, or the 300 takes the test records.
4. **The trim band.** A `--trim` band under the bottom half of one phrase, drawn as a thick offset underline so it can never reach the line above. In dark, the phrase turns `--yellow` instead. The hero line and the link previews only.

## Motion

- **Motion follows state.** The hero strip is driven by the clip's own time (`requestVideoFrameCallback`): bars stream red while the clip records, turn gray and get their "New Recording 2" label the moment it stops. The timing chart plays the 600 ms after stop at real speed when it scrolls into view, with a ¼× replay. The 300 bars record in left to right once.
- **Nothing on a timer, nothing looping without a reason.** The hero video loops because the clip is the product; everything else plays once.
- **Reduced motion and dark mode** draw the settled state. The hero clip is light only (the motion captures are light), so dark shows the dark recording screen as a still and the strip settled.
- Easing `cubic-bezier(0.23, 1, 0.32, 1)`; presses scale to 0.97; fades 160 ms; labels rise 6px over 350 ms.

## Page grammar

The README's big sibling. A hero with the real app moving, Bassim's line, then one section per thing you can't see in a screenshot (stop, the disk, the 300), then the things you can (parity, the other screens, the devices), then what's in, how to build it, and the name. Every section has its own layout: chart card, phone and diagram, full-width bars, centered pair, scrolling reel, device row, two-column text, code card, centered word.

## Files

```
brand/
├ BRAND.md          this
├ references.md     what shaped it, and what was left out
├ specimen.html     the system in use, light and dark
├ fonts/            Funnel Display, Funnel Sans, Geist Mono (woff2, OFL)
├ logo/
│ ├ gen.mjs         bun logo/gen.mjs rebuilds everything below from src/
│ ├ src/            Funnel Display 700 instance + OFL
│ ├ wordmark(-dark,-mono).svg  mark(-dark,-mono).svg  lockup(-dark,-mono).svg  + PNGs at 512 tall
│ ├ favicon.svg     follows prefers-color-scheme;  favicon-32.png  apple-touch-icon.png  icon-512.png
│ ├ app-icon(-dark,-tinted).svg  app-icon(-dark,-tinted)-1024.png
│ └ explore-a-playhead.svg  explore-b-button.svg  explore-c-waveform.svg
├ assets/           HTML sources and their PNGs, rendered with shoot.mjs
│ ├ og.html → og.png                    1200 × 630, link preview
│ ├ github.html → github.png            1280 × 640, GitHub social preview
│ ├ readme-{light,dark}.html → .png      838 × 300 @2x, transparent, README <picture>
│ └ x-1-light-dark  x-2-stop  x-3-devices  x-4-300  x-5-quote   1600 × 900 for X
└ shots/            specimen at 390, 1035, 1440, light and dark
```

Render one asset: `bun ~/.agents/skills/brand-it/scripts/shoot.mjs brand/assets/og.html 1200x630 brand/assets/og.png` (README headers: `838x300@2 … --clear`).
