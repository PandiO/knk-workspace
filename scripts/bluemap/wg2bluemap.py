#!/usr/bin/env python3
"""Turn K&K town/district WorldGuard regions into BlueMap marker-sets.

Usage: wg2bluemap.py <regions.yml> <bluemap map .conf>
Rewrites the block between the '# >>> knk-regions' / '# <<< knk-regions' lines
at the end of the map config (added on first run). Towns = priority 10,
districts = priority 20 (docs/architecture/managed-worldguard-regions.md).
"""
import json, sys, yaml

SETS = {  # priority -> (set id, label, line rgb, fill alpha, sorting)
    10: ("knk-towns", "Towns", (230, 180, 40), 0.25, 0),
    20: ("knk-districts", "Districts", (60, 140, 255), 0.15, 1),
}
SHAPE_Y = 64      # height of the flat overlay; depth-test off draws it on top anyway
BEGIN, END = "# >>> knk-regions", "# <<< knk-regions"

def outline(r):
    if r.get("type") == "poly2d":
        return [{"x": p["x"], "z": p["z"]} for p in r["points"]]
    a, b = r["min"], r["max"]  # cuboid: block coords, +1 to cover the max block
    x1, z1, x2, z2 = a["x"], a["z"], b["x"] + 1, b["z"] + 1
    return [{"x": x1, "z": z1}, {"x": x2, "z": z1}, {"x": x2, "z": z2}, {"x": x1, "z": z2}]

def main(regions_file, conf_file):
    regions = (yaml.safe_load(open(regions_file)) or {}).get("regions") or {}
    sets = {sid: {"label": lab, "toggleable": True, "default-hidden": False,
                  "sorting": srt, "markers": {}} for sid, lab, _, _, srt in SETS.values()}
    counts = {}
    for rid, r in sorted(regions.items()):
        prio = r.get("priority", 0)
        if prio not in SETS or r.get("type") not in ("cuboid", "poly2d"):
            continue
        sid, lab, rgb, alpha, srt = SETS[prio]
        pts = outline(r)
        cx = sum(p["x"] for p in pts) / len(pts); cz = sum(p["z"] for p in pts) / len(pts)
        detail = f"<b>{rid}</b><br>{lab[:-1]}" + (f"<br>parent: {r['parent']}" if r.get("parent") else "")
        sets[sid]["markers"][rid] = {
            "type": "shape", "label": rid, "detail": detail,
            "position": {"x": round(cx), "y": SHAPE_Y, "z": round(cz)},
            "shape": pts, "shape-y": SHAPE_Y, "depth-test": False, "sorting": srt,
            "line-width": 3 if prio == 10 else 2,
            "line-color": {"r": rgb[0], "g": rgb[1], "b": rgb[2], "a": 1.0},
            "fill-color": {"r": rgb[0], "g": rgb[1], "b": rgb[2], "a": alpha},
        }
        counts[lab] = counts.get(lab, 0) + 1
    block = f"{BEGIN}\nmarker-sets: {json.dumps(sets, indent=2)}\n{END}\n"
    text = open(conf_file).read()
    if BEGIN in text:
        text = text[:text.index(BEGIN)] + text[text.index(END) + len(END):].lstrip("\n")
    open(conf_file, "w").write(text.rstrip("\n") + "\n\n" + block)
    print("markers written:", counts or "none (no priority 10/20 regions found)")

if __name__ == "__main__":
    main(*sys.argv[1:3])
