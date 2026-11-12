#!/usr/bin/env python3
"""Count chunk Status / isLightOn / DataVersion per region file (no NBT library).
Usage: chunkcheck.py <region dir> <min rx> <max rx> <min rz> <max rz>"""
import os, sys, zlib, gzip, struct, collections

def field(data, tag_type, name):
    key = bytes([tag_type]) + struct.pack(">H", len(name)) + name
    i = data.find(key)
    if i < 0:
        return None
    i += len(key)
    if tag_type == 8:
        n = struct.unpack(">H", data[i:i + 2])[0]
        return data[i + 2:i + 2 + n].decode("utf-8", "replace")
    if tag_type == 1:
        return data[i]
    if tag_type == 3:
        return struct.unpack(">i", data[i:i + 4])[0]

def chunks(path):
    with open(path, "rb") as f:
        buf = f.read()
    for idx in range(1024):
        off = int.from_bytes(buf[idx * 4:idx * 4 + 3], "big") * 4096
        if not off:
            continue
        length, ctype = struct.unpack(">IB", buf[off:off + 5])
        raw = buf[off + 5:off + 4 + length]
        try:
            data = zlib.decompress(raw) if ctype == 2 else gzip.decompress(raw) if ctype == 1 \
                else raw if ctype == 3 else None
        except Exception:
            data = None
        yield idx, ctype, data

def main(d, x0, x1, z0, z1):
    x0, x1, z0, z1 = map(int, (x0, x1, z0, z1))
    total = collections.Counter(); light = collections.Counter(); ver = collections.Counter()
    samples = collections.defaultdict(list); grid = {}
    for rz in range(z0, z1 + 1):
        for rx in range(x0, x1 + 1):
            p = os.path.join(d, f"r.{rx}.{rz}.mca")
            if not os.path.exists(p):
                grid[rx, rz] = " "; continue
            n = bad = 0
            for idx, ctype, data in chunks(p):
                n += 1
                cx, cz = rx * 32 + idx % 32, rz * 32 + idx // 32
                if data is None:
                    st = f"unreadable(compression {ctype})"
                else:
                    st = field(data, 8, b"Status") or "no-status"
                    light[field(data, 1, b"isLightOn")] += 1
                    ver[field(data, 3, b"DataVersion")] += 1
                total[st] += 1
                if st not in ("minecraft:full", "full"):
                    bad += 1
                    if len(samples[st]) < 3:
                        samples[st].append(f"chunk {cx},{cz} = block {cx * 16},{cz * 16}")
            grid[rx, rz] = "#" if bad == 0 else ("X" if bad == n else "x")
        print(f"z {rz:>3} done", file=sys.stderr)
    print("     x: " + "".join(str(abs(x) % 10) for x in range(x0, x1 + 1)) + "   # all full, x some not full, X none full")
    for rz in range(z0, z1 + 1):
        print(f"z {rz:>3}:  " + "".join(grid[rx, rz] for rx in range(x0, x1 + 1)))
    print("\nStatus:", dict(total.most_common()))
    print("isLightOn:", dict(light.most_common()))
    print("DataVersion:", dict(ver.most_common()))
    for st, s in samples.items():
        print(f"  e.g. {st}: " + "; ".join(s))

if __name__ == "__main__":
    main(*sys.argv[1:6])
