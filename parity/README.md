# parity

A number for "does retake move like Voice Memos", and a loop that lets small models push that number down.

```
reference.mov ─┐                                    ┌─ table: error % and geometry pt per move
               ├─ frames ─ moves ─ align ─ measure ─┤─ score.json, curves.json
candidate.mov ─┘                                    └─ move-<id>.png: frames side by side + curves

parity/loop:  worst move ─► N agents (own worktree + branch) ─► rebuild + record in the sim ─► score ─► keep the best
```

## Run it

```sh
parity/score reference.mov candidate.mov                 # table for all 16 moves
parity/score reference.mov candidate.mov --out out/      # + score.json, curves.json, move-*.png
parity/score reference.mov candidate.mov --moves 1,3,4a  # just these
parity/score recording.mov --events                      # what the segmenter found, and which move each burst became

parity/record . runs/now.mov                             # build this tree on the Mac and record the script in the sim

parity/loop --target reference.mov --moves 1,3,4a --agents 3 --rounds 4 --model claude-haiku-5-5
```

`parity/score` and `parity/loop` run in their own `systemd-run` scope capped at 3 GB. Videos are decoded one frame at a time; a recording costs about 25 MB of cached features (`parity/.cache`).

`parity/loop` options: `--start` (commit to tune from, default `HEAD`), `--base` (existing recordings of `--start`, comma-separated, saves takes), `--takes 3` (record every candidate three times and use each move's median), `--metric error|geometry`, `--model a,b` (agents take turns, e.g. `claude-haiku-5-5,claude-sonnet-5-5`), `--slots 1,2` (record in two simulators at once; each slot is its own build folder on the Mac, about 1.5 GB), `--merge` (fast-forward the current branch to the winner at the end). Every experiment is a commit on `parity/<run>-r<round>a<agent>`; `parity/<run>` follows the winners. Each round's prompts, transcripts, strips and takes are in `parity/runs/<run>/round-<n>/`, and every trial is a line in `log.jsonl`.

The agents run `claude -p --restricted`: no shell, file tools confined to their worktree and the round folder. They see the move's numbers, the strip, the files that drive the move and every earlier attempt with its score, and each one in a round gets a different lever (best guess, speed only, curve shape only, start timing, bolder).

## How it works

**The script.** `UITests/ParityScript.swift` is the fixed script recorded on device (expand, switch, collapse, menu, record, full sheet, pause, resume, Done, Select, tick, Done, back, All Recordings) with a second of rest between moves. `script.json` names the 16 moves and the files behind each; `script.npz` holds where on screen each move changes things, taken from a clean simulator take.

**Frames.** Every frame is decoded at 2 pt per pixel with its real timestamp. Frames the recorder repeated are dropped, and so is a single frame that jumps away from both neighbours while they agree, or jumps back to a copy of an earlier frame (simctl emits both on a loaded Mac). Then each frame is snapped to its burst's 60 or 120 Hz refresh grid, and a capture late enough to land in the next frame's slot moves back one: the simulator renders identical animation states run to run, but stamps them with up to a frame of capture jitter.

**Moves.** A move starts when at least 12 cells of 8 pt change after 0.6 s of rest. Cells that keep changing on their own (the live waveform and the edge it grows into, a running timer) are busy: they can't start a move and aren't scored. The bursts are matched to the script in order by where they change the screen, so launch, Control Center and stray bursts are skipped.

**Onset.** Each move is aligned at the start of its main motion: the rise from 10% to 30% of the move's change, extended back to zero. A tap highlight stays under 10%, so it can't shift the alignment, and the line falls between frames. The frame before a move is static, so its timestamp is ignored. With the refresh grid, this took the same-build noise on a row expand from 25% to 1.3%.

**Error (%).** The share of the move's on-screen change that is out of step between the two takes, averaged from 50 ms before onset until 250 ms after the slower take settles. 0 means the same frames at the same times after onset. It covers slides, fades, scales and morphs alike.

**Geometry (pt).** One-dimensional optical flow on row and column means in three bands: every textured window of the frame before the move is followed forward, and every window of the settled frame backward, searched only near where its own speed puts it next (list rows repeat every ~60 pt). Windows that move together become *things*: a block of rows, a sheet edge, a sliding page. Geometry is the median distance between where each take's moving content is at the same moment. `curves.json` has each thing's offset over time, and the strip plots each thing's share of the way for both takes.

**Timing.** `half` is when the main thing is halfway, `settle` when it stays within 1 pt of its end. "Skipped refreshes" counts frames the app dropped while moving; a take with several is janky and its score for that move is not to be trusted.

## What it measured

All takes are simulator recordings of the parity script on an iPhone 16 Pro Max, iOS 27, recorded on the Mac while it was busy.

| | rows (1, 3, 4a) | all 16 moves |
| --- | --- | --- |
| a take against itself | 0.00% / 0.0 pt | 0.00% |
| same build, two takes (noise) | 1.4%, 1.1%, 0.2% / 0.3, 0.2, 0.0 pt | 9.1% |
| row spring changed to `.spring(duration: 0.42, bounce: 0.18)` | 9.9%, 10.7%, 10.9% / 2.2, 2.5, 2.5 pt | 12.2% |

The changed spring also lifts 2 switch (35% vs 17% noise), 9a Select (13% vs 8%) and 9c leave Select (6.0% vs 1.1%), which collapse and expand rows too. A second altered build (Select fade 0.2 → 0.6 s, new-row insert 0.32 → 0.8 s) shows in 9a (geometry 25 pt vs 1.6 pt noise) and 9c (6.5% vs 1.1%); the insert change hides in Done's noise.

Same-build noise per move:

| noise | moves |
| --- | --- |
| under 4% | 1 expand, 3 collapse, 4a expand, 5 record, 9b tick, 9c leave Select, 10a back |
| 5–9% | 4c menu closes, 6 full sheet (finger-driven in part), 9a Select, 10b All Recordings |
| 11–34% | 2 switch, 4b menu opens, 7a pause, 7b resume, 8 Done |

The noisy ones are noisy because retake isn't repeatable there on a loaded Mac, not because of the scorer:

- **2 switch (17%)**: the list jumps for one frame when one row collapses as the next expands, at a different moment each take. That's a real glitch to fix.
- **4b menu opens (34%)**: the glass menu dropped 10 refreshes in one take and none in the other.
- **8 Done (31%)**: the app stalls for one or two frames while it closes the file, in some takes.
- **7a, 7b pause and resume (11%, 16%)**: mostly the live waveform stopping and starting around the button.

So the loop can tune the first group against one take each; the rest need a fix first (2, 8), or `--takes 3`.

Two limits of simulator takes: now and then a take's capture falls one refresh behind partway through a move, which no timestamp shows (about one move in ten; 8% instead of 2%), and geometry can lock onto the next list row (about 40 pt off) on a morphing move. `--takes 3` takes the median per move, and the loop scores on error unless told otherwise.

**Convergence.** The target was recorded from a build whose row spring was changed to `.spring(duration: 0.42, bounce: 0.18)`; that tree was deleted and the value never entered the repo. From main's `.smooth(duration: 0.3)`, five rounds of three Haiku 5.5 agents (`--moves 1,3,4a`) found:

| round | kept | error |
| --- | --- | --- |
| start | `.smooth(duration: 0.3)` | 10.49% |
| 1 | `.smooth(duration: 0.36)` | 7.23% |
| 2 | nothing better (bounce at 0.36 s; 0.32 s) | 7.23% |
| 3 | `.spring(duration: 0.36, bounce: 0.12)` | 6.26% |
| 4 | `.spring(duration: 0.40, bounce: 0.12)` | 3.68% |
| 5 | `.spring(duration: 0.40, bounce: 0.17)` | 2.79% |

Noise for these three moves is about 0.9%. The 15 agent calls cost $0.06 in all; the 20 minutes went to the simulator (75 s a take, one take at a time). Round 2 stalled because the answer needs speed and bounce to move together, so agents now switch to new levers after a stalled round, one of them "both at once".

Three more rounds from there with four agents, Haiku and Sonnet taking turns, kept nothing: both Sonnet agents proposed `.spring(duration: 0.42, bounce: 0.17)` (2.66%, then 3.02%), inside the acceptance margin, and Haiku pushed bounce too high (6–8%). For scale, a fresh take of the exact hidden spring scores 2.08% against the target, and the loop's `.spring(duration: 0.40, bounce: 0.17)` scores 2.81% and 4.19% in two takes (the second has one late-capture move). The loop got into the noise around the true value; telling 0.40 s from 0.42 s needs more takes per candidate.

## What the device recordings need

Apple's and retake's lists will show different titles and dates. Geometry is built not to care (it follows where content moves, not what it is) and the error blurs text toward bars, but neither has met real Apple footage yet: the first device pair will show how much of the error is content, and the `--events` listing will show whether every move is found. What the recordings need:

- iPhone 16 Pro Max, portrait, light mode, Do Not Disturb on, the same text size in both apps.
- At least 1.5 s of stillness between moves (the segmenter needs 0.6 s; the tail of a spring needs the rest), and nothing else on screen moving.
- Quick, clean taps. The onset is the first visible reaction, and a long press shows a highlight first.
- The same starting state: at least two recordings at the top of the list, nothing expanded, the same list position.
- The swipe up (move 6) is driven by the finger, so only the part after release compares; swipe the same way in both.
- Two takes of each app if there's time: that measures the device noise floor per move, the way the table above does for the simulator.
- `reference/device/` is gitignored: the recordings show real titles and dates, and the repo is public.

Check the segmentation first with `parity/score reference/device/apple.mov --events`; every move should map to a burst.
