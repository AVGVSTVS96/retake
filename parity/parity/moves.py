import json
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from scipy.ndimage import binary_dilation

from .features import CELL, Features

SCRIPT = Path(__file__).resolve().parent.parent / "script.json"
STATUS_BAR = 56 // CELL
CHANGE = 3.0
BUSY_WINDOW = 1.0
BUSY_CHANGES = 3
BUSY_RECENT = 0.25
MIN_CELLS = 12
REST = 0.6
FOOTPRINT = 0.4


@dataclass
class Event:
    onset: int
    footprint: np.ndarray
    busy: np.ndarray


def changes(f: Features) -> np.ndarray:
    moved = np.zeros(f.thumbs.shape, bool)
    moved[1:] = np.abs(np.diff(f.thumbs, axis=0)) > CHANGE
    moved[:, :STATUS_BAR] = False
    return moved


def counter(f: Features, moved: np.ndarray):
    counts = np.concatenate([np.zeros((1, *moved.shape[1:]), np.int32), np.cumsum(moved, axis=0, dtype=np.int32)])
    return lambda until, seconds: counts[np.searchsorted(f.times, until, side="right")] - counts[np.searchsorted(f.times, until - seconds, side="right")]


def busy(f: Features, moved: np.ndarray) -> np.ndarray:
    """Cells still changing after a second of change, and their neighbours: a live waveform and the front it
    grows into, a running timer. The settling tail of the previous move has gone quiet by then."""
    since = counter(f, moved)
    before = f.times - 1e-6
    ongoing = (since(before, BUSY_WINDOW) >= BUSY_CHANGES) & (since(before, BUSY_RECENT) > 0)
    return binary_dilation(ongoing, np.ones((1, 5, 5), bool))


def events(f: Features) -> list[Event]:
    """Each burst of change that follows a rest, with the cells it touched in its first moments. Its busy
    cells are the ones animating on their own just before it or in the calm before the next burst."""
    moved = changes(f)
    steady = busy(f, moved)
    since = counter(f, moved)
    active = np.flatnonzero((moved & ~steady).sum(axis=(1, 2)) >= MIN_CELLS)
    onsets = active[np.diff(f.times[active], prepend=-np.inf) >= REST]
    ends = [*f.times[onsets[1:]], f.times[-1]]
    found = []
    for onset, end in zip(onsets, ends):
        until = np.searchsorted(f.times, f.times[onset] + FOOTPRINT, side="right")
        later = binary_dilation(since(end - 0.15, 0.5) >= BUSY_CHANGES, np.ones((5, 5), bool))
        found.append(Event(int(onset), moved[onset:until].any(axis=0) & ~steady[onset], steady[onset] | later))
    return found


def script() -> list[dict]:
    return json.loads(SCRIPT.read_text())


def align(template: list[np.ndarray], found: list[Event], gap: float = 0.05) -> list[Event | None]:
    """Order-preserving best match of a recording's events to the script's moves (Needleman-Wunsch on footprint
    overlap), so launch, Control Center and other extra bursts are skipped."""
    n, m = len(template), len(found)
    sim = np.array([[float((t & e.footprint).sum() / max(1, (t | e.footprint).sum())) for e in found] for t in template])
    score = np.zeros((n + 1, m + 1))
    score[1:, 0] = -gap * np.arange(1, n + 1)
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            score[i, j] = max(score[i - 1, j - 1] + sim[i - 1, j - 1], score[i - 1, j] - gap, score[i, j - 1])
    picked, i, j = [None] * n, n, m
    while i and j:
        if score[i, j] == score[i - 1, j - 1] + sim[i - 1, j - 1]:
            picked[i - 1] = found[j - 1]
            i, j = i - 1, j - 1
        elif score[i, j] == score[i - 1, j] - gap:
            i -= 1
        else:
            j -= 1
    return picked
