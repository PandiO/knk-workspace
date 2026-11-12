#!/usr/bin/env python3
"""Turn K&K town/district WorldGuard regions into BlueMap marker-sets.

Usage: wg2bluemap.py <regions.yml> <map .conf> [floor-y] [ceil-y]
Towns = priority 10, districts = priority 20 (managed-worldguard-regions.md).
Each region becomes an extrude marker (a see-through volume) at its own WG
height, clamped to floor-y..ceil-y (default 20..120) so full-height regions
don't become sky-high walls. A town gets holes where its districts are, so a
click inside a district reaches the district. Rewrites only the block between
'# >>> knk-regions' and '# <<< knk-regions'.
"""
import json, sys, yaml

SETS = {  # priority -> (set id, label, line rgb, fill alpha, sorting)
    10: ("knk-towns", "Towns", (230, 180, 40), 0.12, 0),
    20: ("knk-districts", "Districts", (60, 140, 255), 0.20, 1),
}
BEGIN, END = "# >>> knk-regions", "# <<< knk-regions"

def outline(r):
    if r.get("type") == "poly2d":
        return [{"x": p["x"], "z": p["z"]} for p in r["points"]]
    a, b = r["min"], r["max"]  # cuboid in block coords; +1 covers the max block
    x1, z1, x2, z2 = a["x"], a["z"], b["x"] + 1, b["z"] + 1
    return [{"x": x1, "z": z1}, {"x": x2, "z": z1}, {"x": x2, "z": z2}, {"x": x1, "z": z2}]

def heights(r):
    if r.get("type") == "poly2d":
        return r.get("min-y", -64), r.get("max-y", 319) + 1
    return r["min"]["y"], r["max"]["y"] + 1

def main(regions_file, conf_file, floor=20, ceil=120):
    floor, ceil = int(floor), int(ceil)
    regions = (yaml.safe_load(open(regions_file)) or {}).get("regions") or {}
    keep = {rid: r for rid, r in regions.items()
            if r.get("priority") in SETS and r.get("type") in ("cuboid", "poly2d")}
    children = {}
    for rid, r in keep.items():
        if r["priority"] == 20 and r.get("parent") in keep:
            children.setdefault(r["parent"], []).append(rid)
    sets = {sid: {"label": lab, "toggleable": True, "default-hidden": False,
                  "sorting": srt, "markers": {}} for sid, lab, _, _, srt in SETS.values()}
    counts = {}
    for rid, r in sorted(keep.items()):
        sid, lab, rgb, alpha, srt = SETS[r["priority"]]
        pts = outline(r)
        lo, hi = heights(r)
        lo, hi = max(lo, floor), min(hi, ceil)
        if hi <= lo:
            lo, hi = floor, ceil
        cx = sum(p["x"] for p in pts) / len(pts); cz = sum(p["z"] for p in pts) / len(pts)
        kids = sorted(children.get(rid, []))
        detail = f"<b>{rid}</b><br>{lab[:-1]}"
        if r.get("parent"):
            detail += f"<br>parent: {r['parent']}"
        if kids:
            detail += "<br>districts: " + ", ".join(kids)
        m = {"type": "extrude", "label": rid, "detail": detail,
             "position": {"x": round(cx), "y": hi, "z": round(cz)},
             "shape": pts, "shape-min-y": lo, "shape-max-y": hi,
             "depth-test": True, "sorting": srt,
             "line-width": 3 if r["priority"] == 10 else 2,
             "line-color": {"r": rgb[0], "g": rgb[1], "b": rgb[2], "a": 1.0},
             "fill-color": {"r": rgb[0], "g": rgb[1], "b": rgb[2], "a": alpha}}
        if kids:
            m["holes"] = [outline(keep[k]) for k in kids]
        sets[sid]["markers"][rid] = m
        counts[lab] = counts.get(lab, 0) + 1
    block = f"{BEGIN}\nmarker-sets: {json.dumps(sets, indent=2)}\n{END}\n"
    text = open(conf_file).read()
    if BEGIN in text:
        text = text[:text.index(BEGIN)] + text[text.index(END) + len(END):].lstrip("\n")
    open(conf_file, "w").write(text.rstrip("\n") + "\n\n" + block)
    print("markers written:", counts or "none (no priority 10/20 regions found)",
          f"| height band {floor}..{ceil}")

if __name__ == "__main__":
    main(*sys.argv[1:5])
