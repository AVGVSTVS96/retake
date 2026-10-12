import hashlib
import json
from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np

from .video import POINTS, WIDTH, frames

VERSION = 5
CACHE = Path(__file__).resolve().parent.parent / ".cache"
CELL = 8
BANDS = 3


@dataclass
class Features:
    """What the scorer keeps of a recording: per-frame timestamps, an 8 pt thumbnail, and row/column
    profiles of the working-resolution frame in three bands."""

    path: str
    times: np.ndarray
    thumbs: np.ndarray
    rows: np.ndarray
    cols: np.ndarray
    dropped: int

    @property
    def pt(self) -> float:
        return POINTS / WIDTH


def bands(n: int) -> list[slice]:
    edges = np.linspace(0, n, BANDS + 1).round().astype(int)
    return [slice(a, b) for a, b in zip(edges[:-1], edges[1:])]


def extract(path: str) -> Features:
    times, thumbs, rows, cols = [], [], [], []
    for frame in frames(path):
        gray = frame.gray
        h, w = gray.shape
        times.append(frame.time)
        thumbs.append(cv2.resize(gray, (w * 2 // CELL, h * 2 // CELL), interpolation=cv2.INTER_AREA))
        rows.append([gray[:, band].mean(axis=1) for band in bands(w)])
        cols.append([gray[band].mean(axis=0) for band in bands(h)])
    times, thumbs = np.array(times), np.stack(thumbs).astype(np.float32)
    keep = fresh(times, thumbs)
    return Features(path, retime(times[keep]), thumbs[keep], np.array(rows, np.float32)[keep],
                    np.array(cols, np.float32)[keep], int((~keep).sum()))


def fresh(times: np.ndarray, thumbs: np.ndarray) -> np.ndarray:
    """Drops what the recorder got wrong: a frame emitted twice, and a single stale or torn frame, which jumps
    away from both neighbours while they agree, or jumps back to a copy of a frame shown a moment earlier.
    Real motion never visits a state and comes straight back within one refresh."""
    keep = np.ones(len(thumbs), bool)
    gap = lambda i, j: np.abs(thumbs[i] - thumbs[j]).mean()
    for i in range(1, len(thumbs) - 1):
        before, after = gap(i, i - 1), gap(i, i + 1)
        if before < 0.05 and times[i] - times[i - 1] < 0.01:
            keep[i] = False
            continue
        jump = min(before, after)
        older = min((gap(i, j) for j in range(max(0, i - 8), i - 1)), default=np.inf)
        keep[i] = not (jump > 2 and (gap(i + 1, i - 1) < 0.4 * jump or older < 0.25 * jump))
    return keep


def retime(times: np.ndarray) -> np.ndarray:
    """Puts frames back on the display's refresh grid. The app renders each animation frame for a vsync, but
    simctl stamps it whenever the capture lands, up to a frame late, so two takes of the same build show
    identical states at jittered times. Within a burst every frame is one or more refreshes after the last;
    a burst that doesn't fit a 60 or 120 Hz grid keeps its timestamps."""
    out = times.copy()
    gaps = np.diff(times)
    starts = np.flatnonzero(np.r_[True, gaps > 0.045])
    for a, b in zip(starts, [*starts[1:], len(times)]):
        if b - a < 3:
            continue
        burst = times[a:b] - times[a]
        typical = np.median(np.diff(burst))
        period = min((1 / 60, 1 / 120), key=lambda p: abs(p - typical))
        steps = np.zeros(b - a, int)
        for k in range(1, b - a):
            steps[k] = max(steps[k - 1] + 1, round(burst[k] / period))
        residual = burst - steps * period
        if np.ptp(residual) < period:
            out[a:b] = times[a] + steps * period + np.median(residual)
    return np.maximum.accumulate(out)


def load(path: str) -> Features:
    stat = Path(path).stat()
    key = hashlib.sha1(json.dumps([str(Path(path).resolve()), stat.st_size, stat.st_mtime_ns, VERSION]).encode()).hexdigest()[:16]
    cached = CACHE / f"{key}.npz"
    if cached.exists():
        with np.load(cached) as data:
            return Features(path, data["times"], data["thumbs"].astype(np.float32), data["rows"].astype(np.float32),
                            data["cols"].astype(np.float32), int(data["dropped"]))
    features = extract(path)
    CACHE.mkdir(exist_ok=True)
    np.savez(cached, times=features.times, thumbs=np.round(features.thumbs).astype(np.uint8),
             rows=features.rows.astype(np.float16), cols=features.cols.astype(np.float16), dropped=features.dropped)
    return load(path)
