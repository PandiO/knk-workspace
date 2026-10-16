#!/usr/bin/env python3
"""Reference simulation for docs/specs/gate-structure-animation/DRAWBRIDGE_KEYFRAME_ANIMATION.md.

Pure Python 3, no dependencies. Two things:

1. Today's mid-swing path (GateFrameCalculator.calculateRotationPosition without an open scan):
   every scanned block rotated about the anchor on its own and floored to a cell.
2. The proposed keyframed plank (§5.2-5.5, §5.11): strip basis anchor + i*uStep + k*e + y*up,
   naive (8-connected) profile line hinge -> tip, tip(theta) = (K sin theta, (H-1) cos theta),
   one keyframe per tip-cell change, door shape mask sampled with the nearest-row rule (D7).

Rounding is half-up (Java Math.round) so the numbers match a Java port.

Usage:
  python3 drawbridge_keyframes_sim.py                  # tables used in the design doc
  python3 drawbridge_keyframes_sim.py OPEN.tsv CLOSED.tsv
      # cell-for-cell check of door 14's stored scans; TSVs are `mysql -B` exports of
      # gate_opened_block_snapshots / gate_block_snapshots for GateDoorId=14 (WorldX/Y/Z columns)
"""
import csv
import math
import sys


def rnd(x):
    """Java Math.round: half-up."""
    return math.floor(x + 0.5)


# ---------------------------------------------------------------- today's per-block path

def rot(v, k, deg):
    kn = math.sqrt(sum(c * c for c in k))
    k = [c / kn for c in k]
    t = math.radians(deg)
    c, s = math.cos(t), math.sin(t)
    kdv = sum(a * b for a, b in zip(k, v))
    kxv = [k[1] * v[2] - k[2] * v[1], k[2] * v[0] - k[0] * v[2], k[0] * v[1] - k[1] * v[0]]
    return [v[i] * c + kxv[i] * s + k[i] * kdv * (1 - c) for i in range(3)]


def current_frame_cells(W, H, u_step, frame, total=90, max_angle=90):
    cells = set()
    collisions = 0
    for i in range(W):
        for j in range(H):
            rel = [u_step[0] * i, j, u_step[2] * i]
            p = rot(rel, u_step, max_angle * frame / total) if frame else rel
            c = tuple(math.floor(x + 1e-9) for x in p)
            collisions += c in cells
            cells.add(c)
    return cells, collisions


# ---------------------------------------------------------------- proposed keyframes

def profile_line(kt, yt):
    """Naive digital segment (0,0)->(kt,yt), ordered from the hinge: one cell per major-axis step."""
    n = max(abs(kt), abs(yt))
    if n == 0:
        return [(0, 0)]
    return [(rnd(kt * s / n), rnd(yt * s / n)) for s in range(n + 1)]


def tip_path(K, Hm1, max_angle=90.0, samples=9000):
    """[(tip cell, angle at which the tip enters it)], one entry per tip-cell change."""
    path = []
    for s in range(samples + 1):
        ang = max_angle * s / samples
        t = math.radians(ang)
        cell = (rnd(K * math.sin(t)), rnd(Hm1 * math.cos(t)))
        if not path or path[-1][0] != cell:
            path.append((cell, ang))
    return path


def rect_mask(W, H):
    return {(c, v) for c in range(W) for v in range(H)}


def arch_mask(heights):
    return {(c, v) for c, h in enumerate(heights) for v in range(h)}


def keyframe(mask, H, profile, f):
    """Cells (i, k, y) of one keyframe -> sampled mask cell (c, row). f = along-hinge shift per strip."""
    cols = sorted({c for c, _ in mask})
    cmin, cmax = cols[0], cols[-1]
    P = len(profile)
    out = {}
    for p, (k, y) in enumerate(profile):
        row = rnd(p * (H - 1) / (P - 1)) if P > 1 else 0
        for i in range(cmin - abs(k) - 2, cmax + abs(k) + 2):
            a = i + f * k
            if a < cmin - 1e-9 or a > cmax + 1e-9:
                continue
            if abs(a - round(a)) < 1e-9:
                C = [int(round(a))]
            else:
                C = [math.floor(a), math.ceil(a)]
            if all((c, row) in mask for c in C):
                out[(i, k, y)] = (C[0], row)
    return out


def keyframes(mask, diagonal, K=None):
    H = max(v for _, v in mask) + 1
    f, sigma = (0.5, 2) if diagonal else (0.0, 1)
    if K is None:
        K = sigma * (H - 1)          # D1: deck length counted in blocks, L = H
    path = tip_path(K, H - 1)
    return [keyframe(mask, H, profile_line(*tip), f) for tip, _ in path], path


def describe(name, mask, diagonal, K=None):
    frames, _ = keyframes(mask, diagonal, K)
    changes = [len(set(a) ^ set(b)) for a, b in zip(frames, frames[1:])]
    sizes = [len(fr) for fr in frames]
    print(f"  {name:34s} closed {sizes[0]:3d}  open {sizes[-1]:3d}  keyframes {len(frames):2d}  "
          f"mid {min(sizes)}..{max(sizes)}  changes/keyframe {min(changes)}..{max(changes)}")
    return frames


def tables():
    print("Today's path, entity 14 (4x8, 45 deg, no open scan): occupied cells per frame")
    worst = min(range(91), key=lambda fr: len(current_frame_cells(4, 8, [-1, 0, 1], fr)[0]))
    print(f"  worst frame {worst}: {len(current_frame_cells(4, 8, [-1, 0, 1], worst)[0])} of 32 cells; "
          f"cardinal 4x8 at frame 45: {len(current_frame_cells(4, 8, [1, 0, 0], 45)[0])} of 32")
    print("\nProposed keyframes (deck counted in blocks, thin plank, nearest-row sampling)")
    for diagonal in (False, True):
        for W, H in ((3, 4), (4, 6), (4, 8), (7, 10)):
            describe(f"{'45deg' if diagonal else 'cardinal'} {W}x{H}", rect_mask(W, H), diagonal)
    describe("45deg 4x8, K=13 (entity 14 as built)", rect_mask(4, 8), True, K=13)
    describe("cardinal arch 7x9 (7,8,9,9,9,8,7)", arch_mask([7, 8, 9, 9, 9, 8, 7]), False)
    describe("45deg arch 5x7 (6,7,7,7,6)", arch_mask([6, 7, 7, 7, 6]), True)


def door14_check(open_tsv, closed_tsv):
    AX, AY, AZ = 1378, 44, -588   # anchor; uStep (-1,0,1), e (-1,0,0)

    def cells(p):
        return {(int(r['WorldX']), int(r['WorldY']), int(r['WorldZ'])) for r in csv.DictReader(open(p), delimiter='\t')}

    def world(i, k, y):
        return (AX - i - k, AY + y, AZ + i)

    frames, _ = keyframes(rect_mask(4, 8), True, K=13)
    op, cl = cells(open_tsv), cells(closed_tsv)
    print(f"door 14: {len(frames)} keyframes; "
          f"keyframe 0 == closed scan: {set(map(lambda c: world(*c), frames[0])) == cl}; "
          f"last keyframe == open scan: {set(map(lambda c: world(*c), frames[-1])) == op}")


if __name__ == '__main__':
    if len(sys.argv) == 3:
        door14_check(sys.argv[1], sys.argv[2])
    else:
        tables()
