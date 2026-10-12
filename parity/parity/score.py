from dataclasses import dataclass, field

import numpy as np

from .measure import GRID, LEAD, MOVING, Take, Tracks, sample, tracks

TAIL = 0.25
SEEN = 0.6


@dataclass
class Curves:
    times: np.ndarray
    progress: tuple[np.ndarray, np.ndarray]
    error: np.ndarray
    things: list[dict] = field(default_factory=list)


@dataclass
class Result:
    name: str
    error: float
    geometry: float
    jank: list[int]
    timing: dict
    curves: Curves


def window(ref: Take, cand: Take) -> np.ndarray:
    end = min(max(ref.settle, cand.settle) + TAIL, ref.room, cand.room)
    return np.arange(-LEAD, end + 1e-9, GRID)


def compare(name: str, ref: Take, cand: Take, pt: float) -> Result:
    """Error is how much of the move's on-screen change is out of step between the two takes, averaged over
    the move (0 = same frames at the same times after onset). Geometry is the mean distance in points
    between where the moving content sits in each take at the same moment."""
    grid = window(ref, cand)
    calm = ~(ref.busy | cand.busy)
    a = sample(ref.times, ref.thumbs, grid)[:, calm] - ref.start[calm]
    b = sample(cand.times, cand.thumbs, grid)[:, calm] - cand.start[calm]
    da, db = (ref.end - ref.start)[calm], (cand.end - cand.start)[calm]
    total = max(np.abs(da).sum(), np.abs(db).sum(), 1.0)
    error = np.abs(a - b).sum(axis=1) / total
    progress = (a @ da / max(da @ da, 1e-6), b @ db / max(db @ db, 1e-6))
    things, geometry = pair(tracks(ref, grid, pt), tracks(cand, grid, pt))
    timing = {"settle": [round(ref.settle, 3), round(cand.settle, 3)], "half": [half(grid, p) for p in progress]}
    if things:
        lead = things[0]
        shares = [travel(lead[side], lead["direction"]) for side in ("ref", "cand")]
        timing = {"settle": [settled(grid, lead[side], lead["direction"]) for side in ("ref", "cand")],
                  "half": [half(grid, share) for share in shares],
                  "overshoot": [overshoot(share, lead[side]) for share, side in zip(shares, ("ref", "cand"))]}
    return Result(name, float(error.mean() * 100), geometry, [ref.dropped, cand.dropped], timing,
                  Curves(grid, progress, error, things))


def travel(offset: np.ndarray, direction: str) -> np.ndarray:
    """A moving thing's share of its way, from its offset to where it started or where it ends up."""
    seen = offset[~np.isnan(offset)]
    if not len(seen) or not seen[-1 if direction == "from start" else 0]:
        return np.zeros_like(offset)
    return offset / seen[-1] if direction == "from start" else 1 - offset / seen[0]


def settled(grid: np.ndarray, offset: np.ndarray, direction: str) -> float:
    """When a moving thing came within a point of where it ends and stayed."""
    seen = ~np.isnan(offset)
    final = offset[seen][-1] if direction == "from start" and seen.any() else 0.0
    away = np.flatnonzero(seen & (np.abs(offset - final) > 1))
    return round(float(grid[min(away[-1] + 1, len(grid) - 1)]), 3) if len(away) else 0.0


def overshoot(share: np.ndarray, offset: np.ndarray) -> float:
    """How far past its end a moving thing went, in points."""
    seen = offset[~np.isnan(offset)]
    span = np.ptp(seen) if len(seen) else 0
    return round(float(max(np.nanmax(share, initial=1) - 1, 0) * span), 1)


def half(grid: np.ndarray, progress: np.ndarray) -> float | None:
    crossed = np.flatnonzero(progress >= 0.5)
    return round(float(grid[crossed[0]]), 3) if len(crossed) else None


def pair(ref: Tracks, cand: Tracks) -> tuple[list[dict], float]:
    """Matches anchors tracked through most of the move in both takes, keeps the ones that move in either,
    and groups anchors that move together into things: a block of rows, a sheet edge, a sliding page.
    Geometry is the median anchor's mean distance, so a window that loses its feature doesn't swing it."""
    index = {key: i for i, key in enumerate(cand.keys)}
    keys, a, b = [], [], []
    for i, key in enumerate(ref.keys):
        j = index.get(key)
        if j is None:
            continue
        x, y = ref.curves[i], cand.curves[j]
        travel = max(np.nanmax(np.abs(x), initial=0), np.nanmax(np.abs(y), initial=0))
        if travel >= MOVING and (~np.isnan(x)).mean() > SEEN and (~np.isnan(y)).mean() > SEEN:
            keys.append(key)
            a.append(x)
            b.append(y)
    if not keys:
        return [], 0.0
    a, b = np.array(a), np.array(b)
    gap = np.abs(a - b)
    geometry = float(np.median(np.nanmean(gap, axis=1)))
    things, free = [], list(range(len(keys)))
    while free:
        lead = max(free, key=lambda i: np.nanmax(np.abs(a[i])))
        group = [i for i in free if keys[i][:3] == keys[lead][:3] and np.nanmean(np.abs(a[i] - a[lead])) < 4]
        free = [i for i in free if i not in group]
        if len(group) >= 2:
            axis, band, direction, _ = keys[lead]
            spots = [keys[i][3] for i in group]
            things.append({"axis": axis, "band": band, "direction": direction, "span": [min(spots), max(spots)],
                           "anchors": len(group), "ref": np.nanmedian(a[group], axis=0),
                           "cand": np.nanmedian(b[group], axis=0),
                           "error": float(np.median(np.nanmean(gap[group], axis=1)))})
    things.sort(key=lambda t: -t["anchors"] * np.nanmax(np.abs(t["ref"])))
    return things[:4], geometry
