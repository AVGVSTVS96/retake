"""Small-model agents tune retake's motion values until a move matches a reference recording.

Each round picks the worst move, gives it to a few agents, each in its own git worktree and branch off the
best commit so far. Every agent changes animation values, the change is recorded in the simulator and
scored, and the best one becomes the new head if it beats the head by more than the noise."""

import argparse
import json
import shutil
import subprocess
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict, dataclass, field
from pathlib import Path
from queue import Queue

import numpy as np

from .cli import table
from .moves import script
from .pair import Pair, score
from .render import strips

ROOT = Path(__file__).resolve().parent.parent
REPO = ROOT.parent
NAMES = {"claude-haiku-5-5": "Claude Haiku 5.5", "claude-sonnet-5-5": "Claude Sonnet 5.5", "claude-opus-5-5": "Claude Opus 5.5"}
MARGIN = 0.5
SHARE = 0.03
MOMENTS = (0, 0.05, 0.1, 0.15, 0.2, 0.3, 0.4, 0.6)
LEVERS = ("make the change you think most likely to close the gap",
          "change only how fast it moves (duration or response), keeping the curve shape",
          "change only the shape of the curve (bounce, damping fraction, easing or curve type), keeping its speed",
          "change speed and shape together: one value alone may have stalled because the best fit needs both to move",
          "change only when it starts or how parts of it are staggered (delays, or separate timing for parts that move together)",
          "make a bolder change than the obvious one, in whichever direction the numbers point")


@dataclass
class Trial:
    name: str
    round: int
    move: str
    commit: str | None
    change: str
    model: str = ""
    agent: int = 0
    round_kept: bool = False
    takes: list = field(default_factory=list)
    scores: dict = field(default_factory=dict)
    objective: float = float("inf")
    accepted: bool = False
    seconds: float = 0.0


def git(*args: str, cwd: Path = REPO) -> str:
    return subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True, text=True).stdout.strip()


def record(tree: Path, out: Path, slot: str, fixture: Path) -> bool:
    done = subprocess.run([str(ROOT / "record"), str(tree), str(out), slot, *([str(fixture)] if fixture.exists() else [])],
                          capture_output=True, text=True)
    (out.with_suffix(".log")).write_text(done.stdout + done.stderr)
    return done.returncode == 0 and out.exists()


def objective(pairs: list[Pair], moves: list[str], metric: str) -> tuple[float, dict]:
    """Mean over the tuned moves of each move's median across takes: one take now and then lands a frame
    late mid-move, and a median of three ignores it."""
    seen: dict[str, list[float]] = {}
    for pair in pairs:
        for move in pair.moves:
            if move.step["id"] in moves and move.result:
                seen.setdefault(move.step["id"], []).append(move.result.error if metric == "error" else move.result.geometry)
    scores = {m: round(float(np.median(v)), 2) for m, v in seen.items()}
    return (float(np.mean(list(scores.values()))) if len(scores) == len(moves) else float("inf")), scores


def describe(pair: Pair, move_id: str, metric: str) -> str:
    """The move's numbers in the words an agent can act on: how far along each take is at the same moments."""
    move = next(m for m in pair.moves if m.step["id"] == move_id)
    r = move.result
    c = r.curves
    at = lambda values, t: values[min(np.searchsorted(c.times, t), len(values) - 1)]
    ms = lambda v: "never" if v is None else f"{v * 1000:.0f} ms"
    lines = [f"error {r.error:.1f}% (0 = identical), geometry {r.geometry:.1f} pt; scoring on {metric}",
             f"halfway at {ms(r.timing['half'][0])} in the reference vs {ms(r.timing['half'][1])} "
             f"in ours; settled within 1 pt at {ms(r.timing['settle'][0])} vs {ms(r.timing['settle'][1])}"
             + (f"; overshoot past the end {r.timing['overshoot'][0]:.1f} pt vs {r.timing['overshoot'][1]:.1f} pt"
                if "overshoot" in r.timing else ""),
             ]
    if not c.things:
        lines += ["overall change done (0 = start, 1 = settled), reference / ours:",
                  "  " + "  ".join(f"{t * 1000:.0f}ms {at(c.progress[0], t):.2f}/{at(c.progress[1], t):.2f}"
                                   for t in MOMENTS if t <= c.times[-1])]
    for th in c.things[:2]:
        lines.append(f"content at {th['axis']}={th['span'][0]:.0f}-{th['span'][1]:.0f} pt ({th['direction']}), "
                     f"offset in pt from its {'start' if th['direction'] == 'from start' else 'end'} position, reference / ours:")
        lines.append("  " + "  ".join(f"{t * 1000:.0f}ms {at(th['ref'], t):+.0f}/{at(th['cand'], t):+.0f}"
                                      for t in MOMENTS if t <= c.times[-1]))
    return "\n".join(lines)


def prompt(step: dict, details: str, strip: Path, history: list[Trial], lever: str) -> str:
    tried = [f"- {t.change} -> {t.scores.get(step['id'], 'failed')}{' (kept)' if t.accepted else ''}"
             for t in history if t.move == step["id"]]
    return f"""You are tuning one animation in retake, a SwiftUI rebuild of Apple's Voice Memos, so it moves exactly like a reference screen recording of the same action.

Move {step['id']}: {step['name']}
{details}

Frame strip: {strip}
(top row reference, middle row ours, bottom row their difference; columns are seconds after the motion starts; the chart shows progress and the main moving things)

The code that drives this move: {', '.join(step['files'])}

Already tried from earlier rounds (score for this move, lower is better):
{chr(10).join(tried) if tried else '- nothing yet'}

Change the animation values behind this move so ours matches the reference: faster or slower, more or less overshoot, earlier or later. Other attempts run alongside you from the same code, so stick to your lever: {lever}. Change only what this move needs, keep it compiling with the iOS 27 SDK, and add no comments.

Finish with one line: what you changed, from what value to what value."""


def edit(tree: Path) -> str:
    """The experiment in one line, from its diff: each changed line as old -> new."""
    lines = git("diff", "-U0", cwd=tree).splitlines()
    removed = [l[1:].strip() for l in lines if l.startswith("-") and not l.startswith("---")]
    added = [l[1:].strip() for l in lines if l.startswith("+") and not l.startswith("+++")]
    files = sorted({l.split(" b/")[-1].split("/")[-1] for l in lines if l.startswith("diff --git")})
    pairs = [f"{a} -> {b}" for a, b in zip(removed, added)] + removed[len(added):] + added[len(removed):]
    return f"{', '.join(files)}: {'; '.join(pairs)}"[:400]


def agent(tree: Path, text: str, model: str, extra: Path, transcript: Path) -> str:
    """One headless agent with file tools confined to its worktree (and the round's strip), no shell."""
    done = subprocess.run(
        ["claude", "-p", "--model", model, "--restricted", "--strict-mcp-config", "--permission-mode", "acceptEdits",
         "--no-session-persistence", "--max-budget-usd", "1", "--add-dir", str(extra), "--output-format", "json", text],
        cwd=tree, capture_output=True, text=True, timeout=900)
    transcript.write_text(text + "\n\n---\n\n" + done.stdout + done.stderr)
    try:
        return json.loads(done.stdout).get("result", "").strip().splitlines()[-1][:300]
    except (json.JSONDecodeError, IndexError):
        return f"agent failed: {done.stderr.strip()[:200]}"


def main(argv: list[str] | None = None):
    parser = argparse.ArgumentParser(prog="parity loop", description=__doc__.splitlines()[0])
    parser.add_argument("--target", required=True, help="reference recording of the parity script")
    parser.add_argument("--moves", help="comma-separated move ids to tune (default: all)")
    parser.add_argument("--start", default="HEAD", help="commit to tune from")
    parser.add_argument("--base", help="recordings of --start, if they exist already (comma-separated)")
    parser.add_argument("--takes", type=int, default=1, help="record each candidate this many times and use the median")
    parser.add_argument("--agents", type=int, default=3)
    parser.add_argument("--rounds", type=int, default=4)
    parser.add_argument("--model", default="claude-haiku-5-5", help="model id, or a comma-separated list the agents take turns with")
    parser.add_argument("--metric", choices=("error", "geometry"), default="error")
    parser.add_argument("--slots", default="1", help="comma-separated simulator slots to record in parallel")
    parser.add_argument("--run", default=time.strftime("%m%d-%H%M"))
    parser.add_argument("--merge", action="store_true", help="fast-forward the current branch to the best commit")
    args = parser.parse_args(argv)

    steps = {s["id"]: s for s in script()}
    moves = args.moves.split(",") if args.moves else list(steps)
    run = ROOT / "runs" / args.run
    run.mkdir(parents=True, exist_ok=True)
    branch = f"parity/{args.run}"
    head = git("rev-parse", args.start)
    git("branch", "-f", branch, head)
    scoring = threading.Lock()
    slots: Queue = Queue()
    for slot in args.slots.split(","):
        slots.put(slot)
    log = run / "log.jsonl"

    def recorded(tree: Path, out: Path) -> bool:
        slot = slots.get()
        try:
            return record(tree, out, slot, Path(args.target).with_suffix(".fixture.json"))
        finally:
            slots.put(slot)

    def takes(tree: Path, stem: Path) -> list[Path]:
        outs = [stem.with_name(f"{stem.name}-{k}.mov") if args.takes > 1 else stem.with_suffix(".mov") for k in range(args.takes)]
        return [out for out in outs if recorded(tree, out)]

    if args.base:
        bases = [Path(b) for b in args.base.split(",")]
    else:
        tree = run / "trees" / "head-0"
        git("worktree", "add", "-q", "--detach", str(tree), head)
        bases = takes(tree, run / "head-0")
        git("worktree", "remove", "--force", str(tree))
        if not bases:
            raise SystemExit(f"could not record {head}: see {run}/head-0*.log")
    pairs = [score(args.target, str(b), set(moves)) for b in bases]
    pair = pairs[0]
    best, scores = objective(pairs, moves, args.metric)
    print(f"start {head[:8]}: {args.metric} {best:.2f} {scores}\n{table(pair)}\n", flush=True)
    history: list[Trial] = []
    stuck: set[str] = set()

    for number in range(1, args.rounds + 1):
        stuck = stuck if stuck < set(scores) else set()
        move = max(set(scores) - stuck, key=scores.get)
        step = steps[move]
        here = run / f"round-{number}"
        strip = strips(pair, here, only={move})[0]
        details = describe(pair, move, args.metric)
        trees = []
        for k in range(1, args.agents + 1):
            name = f"r{number}a{k}"
            tree = run / "trees" / name
            git("worktree", "add", "-q", "-B", f"{branch}-{name}", str(tree), head)
            models = args.model.split(",")
            stalled = sum(1 for t in history if t.move == move and t.agent == 1 and not t.round_kept)
            trees.append((name, tree, models[(k - 1) % len(models)],
                          prompt(step, details, strip, history, LEVERS[(k - 1 + stalled * args.agents) % len(LEVERS)])))

        def attempt(job) -> Trial:
            name, tree, model, text = job
            began = time.time()
            change = agent(tree, text, model, here, here / f"{name}.txt")
            trial = Trial(name, number, move, None, change, model=model, agent=int(name.split("a")[-1]))
            if not git("status", "--porcelain", "--untracked-files=no", cwd=tree):
                trial.change = f"no change ({change})"
                return trial
            trial.change = edit(tree)
            git("commit", "-qam", f"Parity loop {args.run} {name}, move {move}: {trial.change}\n\n"
                f"Co-Authored-By: {NAMES.get(model, model)} <noreply@anthropic.com>", cwd=tree)
            trial.commit = git("rev-parse", "HEAD", cwd=tree)
            outs = takes(tree, here / name)
            if outs:
                with scoring:
                    pairs = [score(args.target, str(o), set(moves)) for o in outs]
                trial.objective, trial.scores = objective(pairs, moves, args.metric)
                trial.takes = [str(o) for o in outs]
            trial.seconds = round(time.time() - began, 1)
            return trial

        with ThreadPoolExecutor(args.agents) as pool:
            trials = list(pool.map(attempt, trees))
        winner = min(trials, key=lambda t: t.objective)
        if winner.objective < best - max(MARGIN, SHARE * best):
            winner.accepted = True
            head, best = winner.commit, winner.objective
            git("branch", "-f", branch, head)
            pair = score(args.target, winner.takes[0], set(moves))
            scores = winner.scores
            stuck.clear()
        else:
            stuck.add(move)
        for trial in trials:
            trial.round_kept = winner.accepted
            history.append(trial)
            with log.open("a") as f:
                f.write(json.dumps(asdict(trial)) + "\n")
            print(f"round {number} move {move} {trial.name} ({trial.model}): {trial.objective:6.2f}"
                  f"{'  kept' if trial.accepted else ''}  {trial.change}", flush=True)
        for _, tree, _, _ in trees:
            git("worktree", "remove", "--force", str(tree))
        print(f"round {number}: best {args.metric} {best:.2f} at {head[:8]} {scores}\n", flush=True)

    shutil.rmtree(run / "trees", ignore_errors=True)
    git("worktree", "prune")
    print(f"done: {branch} at {head[:8]}, {args.metric} {best:.2f}\n{git('log', '--oneline', f'{args.start}..{branch}')}")
    if args.merge and head != git("rev-parse", args.start):
        git("merge", "--ff-only", branch)
