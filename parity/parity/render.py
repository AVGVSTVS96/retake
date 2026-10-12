from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from .pair import Pair
from .video import frames

COLUMNS = 12
THUMB = 120
REF, CAND, ERR = (40, 40, 40), (230, 70, 50), (60, 120, 220)
FONT = ImageFont.load_default(size=12)


def grab(path: str, wanted: list[float]) -> dict[float, np.ndarray]:
    """The frame on screen at each wanted time: the last one shown at or before it."""
    order = sorted(set(wanted))
    shown, last, k = {}, None, 0
    for frame in frames(path, width=THUMB, rgb=True):
        while k < len(order) and order[k] < frame.time:
            shown[order[k]] = last if last is not None else frame.rgb
            k += 1
        last = frame.rgb
        if k == len(order):
            break
    for t in order[k:]:
        shown[t] = last
    return shown


def strips(pair: Pair, out: Path, only: set[str] | None = None) -> list[Path]:
    picks = []
    for move in pair.moves:
        if move.result and (not only or move.step["id"] in only):
            grid = move.result.curves.times
            picks.append((move, np.linspace(grid[0], grid[-1], COLUMNS)))
    ref = grab(pair.ref.path, [move.onsets[0] + t for move, ts in picks for t in ts])
    cand = grab(pair.cand.path, [move.onsets[1] + t for move, ts in picks for t in ts])
    out.mkdir(parents=True, exist_ok=True)
    written = []
    for move, ts in picks:
        a = [ref[move.onsets[0] + t] for t in ts]
        b = [cand[move.onsets[1] + t] for t in ts]
        path = out / f"move-{move.step['id']}.png"
        sheet(move, ts, a, b).save(path)
        written.append(path)
    return written


def sheet(move, ts, a: list[np.ndarray], b: list[np.ndarray]) -> Image.Image:
    h, w = a[0].shape[:2]
    diff = [np.repeat(np.abs(x.astype(int) - y.astype(int)).max(axis=2, keepdims=True), 3, axis=2) for x, y in zip(a, b)]
    diff = [(255 - np.clip(d * 3, 0, 255)).astype(np.uint8) for d in diff]
    top = 34
    chart = 220
    image = Image.new("RGB", (w * len(ts), top + 3 * h + chart + 10), "white")
    draw = ImageDraw.Draw(image)
    r = move.result
    draw.text((6, 4), f"move {move.step['id']}: {move.step['name']}   error {r.error:.2f}%   geometry {r.geometry:.1f} pt", fill=REF, font=FONT)
    draw.text((6, 18), "rows: reference, candidate, difference.  columns: seconds after onset", fill=(120, 120, 120), font=FONT)
    for i, (t, x, y, d) in enumerate(zip(ts, a, b, diff)):
        for j, img in enumerate((x, y, d)):
            image.paste(Image.fromarray(img), (i * w, top + j * h))
        draw.text((i * w + 3, top + 3), f"{t:+.3f}", fill=(255, 0, 0), font=FONT)
    plot(draw, r.curves, (8, top + 3 * h + 6, image.width - 8, image.height - 4))
    return image


def plot(draw: ImageDraw.ImageDraw, curves, box):
    """Progress of the whole change (0 before, 1 settled) for both takes, the step error, and the main moving
    things' displacement in points on a second scale."""
    x0, y0, x1, y1 = box
    t = curves.times
    half = (y0 + y1) // 2
    px = lambda v: x0 + (v - t[0]) / (t[-1] - t[0]) * (x1 - x0)
    draw.rectangle(box, outline=(200, 200, 200))
    draw.line([(x0, half), (x1, half)], fill=(225, 225, 225))

    def line(values, top, bottom, low, high, color, dash=False):
        points = [(px(tt), bottom - (v - low) / (high - low) * (bottom - top)) for tt, v in zip(t, values) if np.isfinite(v)]
        for k, (p, q) in enumerate(zip(points, points[1:])):
            if not dash or k % 4 < 2:
                draw.line([p, q], fill=color, width=2)

    line(curves.progress[0], y0 + 14, half - 4, -0.1, 1.2, REF)
    line(curves.progress[1], y0 + 14, half - 4, -0.1, 1.2, CAND, dash=True)
    line(curves.error, y0 + 14, half - 4, -0.1, 1.2, ERR)
    draw.text((x0 + 4, y0 + 2), "progress: reference (solid), candidate (dashed); blue = step error", fill=REF, font=FONT)
    things = curves.things[:3]
    if things:
        span = max(np.nanmax(np.abs(np.r_[th["ref"], th["cand"]])) for th in things) or 1
        for k, th in enumerate(things):
            shade = tuple(int(c * (0.4 + 0.3 * k)) for c in (1, 1, 1))
            line(th["ref"], half + 16, y1 - 4, -span, span, REF)
            line(th["cand"], half + 16, y1 - 4, -span, span, CAND, dash=True)
            draw.text((x0 + 4, half + 2 + 0), f"moving things (pt, ±{span:.0f}): " + "; ".join(
                f"{th['axis']} {th['direction']} at {th['span'][0]:.0f}-{th['span'][1]:.0f} pt ({th['error']:.1f} pt off)" for th in things), fill=REF, font=FONT)
