from dataclasses import dataclass
from pathlib import Path

import numpy as np

from .features import Features, load
from .measure import take
from .moves import align, events, script
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


def scripted(f: Features) -> list[tuple[int, float | None] | None]:
    """Each script move's event in this recording: its onset frame and the time the next burst starts."""
    found = events(f)
    with np.load(TEMPLATE) as data:
        picked = align(list(data["footprints"]), found)
    after = {id(e): (f.times[n.onset] if n else None) for e, n in zip(found, [*found[1:], None])}
    return [(e, after[id(e)]) if e else None for e in picked]


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
