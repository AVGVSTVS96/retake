from dataclasses import dataclass

import numpy as np
from numpy.lib.stride_tricks import sliding_window_view
from scipy.ndimage import gaussian_filter

from .features import Features
from .moves import Event

GRID = 1 / 120
LEAD = 0.05
LONGEST = 1.6
HOLD = 0.04
REFRESH = 1 / 60
SETTLED = 0.5
CHANGED = 4.0
HALF = 16
STEP = 6
TEXTURE = 2.0
MATCH = 0.85
REACH = 14
MOVING = 3.0


@dataclass
class Take:
    """One recording's view of one move: frames from just before onset until the next move, plus the same
    resampled onto a fixed grid of times after onset."""

    times: np.ndarray
    thumbs: np.ndarray
    rows: np.ndarray
    cols: np.ndarray
    busy: np.ndarray
    settle: float
    room: float
    onset: float
    dropped: int

    @property
    def start(self) -> np.ndarray:
        return self.thumbs[0]

    @property
    def end(self) -> np.ndarray:
        return self.thumbs[-1]


def take(f: Features, event: Event, next_onset: float | None) -> Take:
    first = f.times[event.onset]
    room = min(LONGEST, (next_onset - first - 0.05) if next_onset is not None else LONGEST)
    stop = np.searchsorted(f.times, first + room, side="right")
    span = slice(event.onset - 1, max(stop, event.onset + 1))
    times = f.times[span]
    thumbs = gaussian_filter(f.thumbs[span], (0, 1, 3))
    calm = ~event.busy
    change = np.abs(thumbs - thumbs[0])[:, calm].sum(axis=1) / max(np.abs(thumbs[-1] - thumbs[0])[calm].sum(), 1.0)
    onset = start(times, change)
    changed = calm & (np.abs(thumbs[-1] - thumbs[0]) > CHANGED)
    still = np.abs(thumbs - thumbs[-1])[:, changed if changed.any() else calm].mean(axis=1) < SETTLED
    moving = np.flatnonzero(~still)
    settle = (times[moving[-1] + 1] - onset) if len(moving) and moving[-1] + 1 < len(still) else first + room - onset
    times = times - onset
    return Take(times, thumbs, f.rows[span], f.cols[span], event.busy, float(settle), float(first + room - onset),
                float(onset), dropped(times[(times >= 0) & (times <= settle)]))


def dropped(times: np.ndarray) -> int:
    """Refreshes the app skipped while it moved: frames that arrived two or more refreshes after the last."""
    return int(np.maximum(np.round(np.diff(times) / REFRESH) - 1, 0).sum())


def start(times: np.ndarray, change: np.ndarray) -> float:
    """When the main motion began: the rise from 10% to 30% of the move's change, extended back to zero.
    A tap highlight stays under 10%. The frame before the move was static, so its timestamp says nothing;
    a level first passed right after rest is placed by the slope of the next frames, at most a refresh back."""
    def crossing(level):
        k = 1 + int(np.argmax(change[1:] >= level))
        if change[k] < level:
            return times[-1]
        if k >= 2 and times[k] - times[k - 1] <= HOLD:
            return times[k - 1] + (level - change[k - 1]) / (change[k] - change[k - 1]) * (times[k] - times[k - 1])
        if k + 1 < len(times) and times[k + 1] - times[k] <= HOLD and change[k + 1] > change[k]:
            slope = (change[k + 1] - change[k]) / (times[k + 1] - times[k])
            return times[k] - min((change[k] - level) / slope, REFRESH)
        return times[k]
    low, high = crossing(0.1), crossing(0.3)
    return float(low - 0.5 * (high - low))


def sample(times: np.ndarray, values: np.ndarray, grid: np.ndarray) -> np.ndarray:
    """What the screen showed at each grid time: frames bridge smoothly across normal frame gaps and hold
    still across rests, where the recorder simply had nothing new to emit."""
    i = np.clip(np.searchsorted(times, grid, side="right") - 1, 0, len(times) - 2)
    gap = times[i + 1] - times[i]
    frac = np.where(gap <= HOLD, np.clip((grid - times[i]) / np.maximum(gap, 1e-9), 0, 1), (grid >= times[i + 1]) * 1.0)
    frac = frac.reshape(-1, *([1] * (values.ndim - 1)))
    return values[i] * (1 - frac) + values[i + 1] * frac


def track(times: np.ndarray, profiles: np.ndarray, template: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Follows every textured window of `template` through `profiles` (in tracking order): one-dimensional
    optical flow on row or column means, which averages text away and keeps the geometry. List rows repeat
    every few dozen points, so each window is only searched near where its own speed puts it next."""
    size = 2 * HALF + 1
    anchors = np.arange(HALF, len(template) - HALF, STEP)
    windows = sliding_window_view(template, size)[anchors - HALF]
    textured = windows.std(axis=1) >= TEXTURE
    anchors, windows = anchors[textured], windows[textured]
    if not len(anchors):
        return anchors, np.zeros((len(profiles), 0))
    norm = lambda w: (w - w.mean(axis=-1, keepdims=True)) / np.maximum(w.std(axis=-1, keepdims=True), 1e-3)
    kernel = norm(windows)
    shift, velocity = np.zeros(len(anchors)), np.zeros(len(anchors))
    out = np.full((len(profiles), len(anchors)), np.nan)
    centers = np.arange(HALF, len(template) - HALF)
    rows = np.arange(len(anchors))
    for k, profile in enumerate(profiles):
        ncc = kernel @ norm(sliding_window_view(profile, size)).T / size
        step = abs(times[k] - times[k - 1]) if k else 0.0
        predicted = anchors + shift + velocity * step
        distance = np.abs(centers[None] - predicted[:, None])
        best = np.argmax(np.where(distance <= REACH, ncc, -np.inf), axis=1)
        peak = ncc[rows, best]
        left, right = ncc[rows, np.maximum(best - 1, 0)], ncc[rows, np.minimum(best + 1, ncc.shape[1] - 1)]
        curve = left - 2 * peak + right
        offset = np.where(curve < 0, np.clip(0.5 * (left - right) / np.where(curve < 0, curve, -1), -0.5, 0.5), 0)
        found = centers[best] + offset - anchors
        good = peak >= MATCH
        if k:
            velocity = np.where(good, (found - shift) / max(step, 1e-3), velocity)
        shift = np.where(good, found, shift)
        out[k] = np.where(good, found, np.nan)
    return anchors, out


@dataclass
class Tracks:
    """Displacement in points over the grid, per anchor, of content found in the frame before the move
    (forward) and in the settled frame after it (backward), along each axis and band."""

    keys: list[tuple[str, int, str, float]]
    curves: np.ndarray


def tracks(t: Take, grid: np.ndarray, pt: float) -> Tracks:
    keys, curves = [], []
    for axis, profiles in (("y", t.rows), ("x", t.cols)):
        for band in range(profiles.shape[1]):
            seq = profiles[:, band]
            for direction, order in (("from start", slice(None)), ("to end", slice(None, None, -1))):
                anchors, moved = track(t.times[order], seq[order], seq[order][0])
                moved = moved[order] * pt
                for a, anchor in enumerate(anchors):
                    keys.append((axis, band, direction, float(anchor * pt)))
                    curves.append(sample_tracked(t.times, moved[:, a], grid))
    return Tracks(keys, np.array(curves).reshape(len(keys), len(grid)))


def sample_tracked(times: np.ndarray, values: np.ndarray, grid: np.ndarray) -> np.ndarray:
    good = ~np.isnan(values)
    if good.sum() < 2:
        return np.full(len(grid), np.nan)
    out = sample(times[good], values[good], grid)
    out[(grid < times[good][0]) | (grid > times[good][-1])] = np.nan
    return out
