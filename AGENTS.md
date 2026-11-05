# retake

Apple's iOS 27 Voice Memos rebuilt in SwiftUI (iPhone, iPad, iPhone Duo), with its site, brand and launch copy. MIT, public.

## Commands

- `bun run check`: oxlint, oxfmt, `tsc` per workspace, `swift format lint`. Lefthook runs it before each commit; CI runs it and the two below.
- `bun run fix`: oxlint, oxfmt and swift format, fixing what they can.
- `scripts/mac scripts/build`: syncs to the Mac, runs xcodegen, builds for the simulator with warnings as errors. Set `RETAKE_MAC` to sync into a folder of your own.
- `scripts/mac scripts/test`: MemoKit's tests on an iOS 27 simulator.
- `scripts/mac scripts/sim …`, `scripts/mac scripts/duo`, `scripts/mac scripts/motion`: screenshots and motion captures into `shots/`.
- `bun --cwd site run dev`, `bun --cwd site run media` (site images from `shots/`), `bun --cwd brand run logo`, `bun --cwd copy run facts`.

## Map

| Folder                  | Job                                                                   | May use                     |
| ----------------------- | --------------------------------------------------------------------- | --------------------------- |
| `Packages/MemoKit`      | the engine: recorder, library, player, editing, transcription         | Apple frameworks only       |
| `App/`                  | the SwiftUI app, a folder per feature; `Design/` is the shared look   | MemoKit, `Activity/`        |
| `Activity/`             | the Live Activity and its intents, compiled into app and widget       | ActivityKit, AppIntents     |
| `Widgets/`              | the widget extension (Live Activity, Control Center button)           | `Activity/`                 |
| `UITests/`              | record, stop, record through the real app                             | the app                     |
| `site/`                 | the page at retake-seven.vercel.app (Vite)                            | `copy/facts.json`, `brand/` |
| `brand/`                | logo generator, fonts, OG and README images                           |                             |
| `copy/`                 | messaging, launch post, `facts.json` counted from this repo           |                             |
| `reference/`, `parity/` | Apple's app frame by frame, and the scorer that compares retake to it |                             |

`project.yml` (XcodeGen) is the Xcode project; the `.xcodeproj` is generated, never committed.

## Rules

| Rule                                                                                          | Enforced by                                                                           |
| --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| It never loses a take: 300 record/stop cycles, each there at the right length                 | `RecorderTests` in `scripts/test`                                                     |
| Swift 6, MainActor by default, no warnings                                                    | `project.yml`, `SWIFT_TREAT_WARNINGS_AS_ERRORS` in `scripts/build` and `scripts/test` |
| Apple's screenshots, strings and footage in `reference/` never ship on the site or in the app | judgment                                                                              |
