import argparse
import json
import sys
from pathlib import Path

import numpy as np

from .pair import Pair, score
from .render import strips


def summary(pair: Pair) -> dict:
    moves = []
    for move in pair.moves:
        entry = {"id": move.step["id"], "name": move.step["name"]}
        r = move.result
        if r:
            entry |= {"error": round(r.error, 2), "geometry_pt": round(r.geometry, 2), "jank": r.jank,
                      "onset_s": [round(o, 3) for o in move.onsets], **r.timing}
        else:
            entry["error"] = None
        moves.append(entry)
    return {"reference": pair.ref.path, "candidate": pair.cand.path, "error": round(pair.error, 2), "moves": moves}


def curves(pair: Pair) -> dict:
    out = {}
    for move in pair.moves:
        if not move.result:
            continue
        c = move.result.curves
        rounded = lambda a: [None if not np.isfinite(v) else round(float(v), 3) for v in a]
        out[move.step["id"]] = {
            "t": rounded(c.times), "progress": [rounded(p) for p in c.progress], "error": rounded(c.error),
            "things": [{k: (rounded(v) if isinstance(v, np.ndarray) else v) for k, v in th.items()} for th in c.things]}
    return out


def table(pair: Pair) -> str:
    lines = [f"{'move':>4}  {'error':>7}  {'geometry':>8}  {'half (ref/cand)':>16}  {'settle (ref/cand)':>18}  name"]
    for move in pair.moves:
        r = move.result
        if not r:
            lines.append(f"{move.step['id']:>4}  {'--':>7}  {'':>8}  {'':>16}  {'':>18}  {move.step['name']} (not found)")
            continue
        half = "/".join("--" if h is None else f"{h * 1000:.0f}" for h in r.timing["half"])
        settle = "/".join(f"{s * 1000:.0f}" for s in r.timing["settle"])
        flag = f"  (skipped refreshes {r.jank[0]}/{r.jank[1]})" if max(r.jank) > 1 else ""
        lines.append(f"{move.step['id']:>4}  {r.error:6.2f}%  {r.geometry:6.1f}pt  {half + ' ms':>16}  {settle + ' ms':>18}  {move.step['name']}{flag}")
    lines.append(f"{'all':>4}  {pair.error:6.2f}%")
    return "\n".join(lines)


def main(argv: list[str] | None = None):
    parser = argparse.ArgumentParser(prog="parity", description="Scores how closely one recording of the parity "
                                     "script moves like another.")
    parser.add_argument("reference")
    parser.add_argument("candidate")
    parser.add_argument("--out", type=Path, help="write score.json, curves.json and a frame strip per move here")
    parser.add_argument("--moves", help="comma-separated move ids to score, e.g. 1,2,4a")
    parser.add_argument("--json", action="store_true", help="print the summary as JSON instead of a table")
    args = parser.parse_args(argv)
    pair = score(args.reference, args.candidate, set(args.moves.split(",")) if args.moves else None)
    report = summary(pair)
    if args.out:
        args.out.mkdir(parents=True, exist_ok=True)
        (args.out / "score.json").write_text(json.dumps(report, indent=1))
        (args.out / "curves.json").write_text(json.dumps(curves(pair)))
        strips(pair, args.out)
    print(json.dumps(report, indent=1) if args.json else table(pair))


if __name__ == "__main__":
    sys.exit(main())
