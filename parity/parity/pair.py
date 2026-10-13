import json
from dataclasses import dataclass
from pathlib import Path

import numpy as np

from .features import Features, load
from .measure import take
from .moves import Event, align, events, script
from .score import Result, compare

TEMPLATE = Path(__file__).resolve().parent.parent / "script.npz"


@dataclass
class Move:
    step: dict
    result: Result | None
    onsets: tuple[float | None, float | None]


@dataclass
class Pair:
    ref: Features
    cand: Features
    moves: list[Move]

    @property
    def error(self) -> float:
        scored = [m.result.error for m in self.moves if m.result]
        return float(np.mean(scored)) if scored else float("nan")


def picks(path: str) -> dict[str, list[float]] | None:
    """A hand-made recording's moves from `<video>.moves.json` beside it: each move's start in seconds, or its
    start and the moment to stop watching it. Device footage repeats moves and has calls, banners and alerts in
    between, so someone names the clean instance of each."""
    sidecar = Path(path).with_suffix(".moves.json")
    if not sidecar.exists():
        return None
    return {k: v if isinstance(v, list) else [v] for k, v in json.loads(sidecar.read_text()).items()}


def scripted(f: Features) -> list[tuple[Event, float | None] | None]:
    """Each script move's event in this recording and when its window closes (the next burst, or the pick's end):
    the picked burst when the recording has picks, otherwise the best order-preserving match to the script."""
    found = events(f)
    after = {id(e): (f.times[n.onset] if n else None) for e, n in zip(found, [*found[1:], None])}
    chosen = picks(f.path)
    if chosen is None:
        with np.load(TEMPLATE) as data:
            return [(e, after[id(e)]) if e else None for e in align(list(data["footprints"]), found)]
    moves = []
    for step in script():
        pick = chosen.get(step["id"])
        if not pick:
            moves.append(None)
            continue
        e = min(found, key=lambda e: abs(f.times[e.onset] - pick[0]))
        moves.append((e, min(pick[1], after[id(e)] or np.inf) if len(pick) > 1 else after[id(e)]))
    return moves


def score(ref_path: str, cand_path: str, only: set[str] | None = None) -> Pair:
    ref, cand = load(ref_path), load(cand_path)
    moves = []
    for step, a, b in zip(script(), scripted(ref), scripted(cand)):
        if only and step["id"] not in only:
            continue
        if not (a and b):
            moves.append(Move(step, None, (None, None)))
            continue
        x, y = take(ref, a[0], a[1]), take(cand, b[0], b[1])
        moves.append(Move(step, compare(step["id"], x, y, ref.pt), (x.onset, y.onset)))
    return Pair(ref, cand, moves)
