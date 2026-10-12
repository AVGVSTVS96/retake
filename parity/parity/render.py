from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from .pair import Pair
from .score import travel
from .video import frames

COLUMNS = 12
THUMB = 120
REF, CAND, ERR = (40, 40, 40), (230, 70, 50), (60, 120, 220)
SHADES = ((40, 40, 40), (120, 120, 120), (170, 170, 170))
TINTS = ((230, 70, 50), (240, 150, 60), (240, 190, 120))
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
            end = min(grid[-1], max(move.result.timing["settle"]) + 0.05)
            picks.append((move, np.linspace(grid[0], end, COLUMNS)))
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
    """Each main moving thing's share of its way (0 where it starts, 1 where it ends, above 1 overshoot),
    reference in grey, candidate in red, and the step error in blue. Without moving things, the share of
    the whole change."""
    x0, y0, x1, y1 = box
    t = curves.times
    top, bottom = y0 + 18 + 14 * min(3, max(1, len(curves.things))), y1 - 6
    px = lambda v: x0 + (v - t[0]) / (t[-1] - t[0]) * (x1 - x0)
    py = lambda v: bottom - (np.clip(v, -0.2, 1.3) + 0.2) / 1.5 * (bottom - top)
    draw.rectangle(box, outline=(200, 200, 200))
    for level in (0, 1):
        draw.line([(x0, py(level)), (x1, py(level))], fill=(225, 225, 225))
    zero = px(0)
    draw.line([(zero, top), (zero, bottom)], fill=(225, 225, 225))

    def line(values, color, width=2):
        points = [(px(tt), py(v)) for tt, v in zip(t, values) if np.isfinite(v)]
        if len(points) > 1:
            draw.line(points, fill=color, width=width)

    line(curves.error, ERR, 1)
    if curves.things:
        legend = []
        for k, th in enumerate(curves.things[:3]):
            line(travel(th["ref"], th["direction"]), SHADES[k])
            line(travel(th["cand"], th["direction"]), TINTS[k])
            seen = th["ref"][np.isfinite(th["ref"])]
            moved = seen[-1] - seen[0] if len(seen) else 0
            legend.append(f"{th['axis']} {th['span'][0]:.0f}-{th['span'][1]:.0f} pt moves {moved:+.0f} pt ({th['direction']}), "
                          f"{th['error']:.1f} pt off")
    else:
        line(curves.progress[0], SHADES[0])
        line(curves.progress[1], TINTS[0])
        legend = ["share of the whole change (no moving content tracked)"]
    draw.text((x0 + 4, y0 + 3), "share of the way: reference grey, candidate red; blue = step error", fill=REF, font=FONT)
    for k, text in enumerate(legend):
        draw.text((x0 + 4, y0 + 17 + 14 * k), f"{k + 1}. {text}", fill=SHADES[k] if curves.things else REF, font=FONT)
