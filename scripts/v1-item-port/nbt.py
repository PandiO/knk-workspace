"""Minimal stdlib NBT reader (gzip'd player .dat files)."""
import gzip, struct, sys, json, os

def _read(f, t):
    if t == 1: return struct.unpack('>b', f.read(1))[0]
    if t == 2: return struct.unpack('>h', f.read(2))[0]
    if t == 3: return struct.unpack('>i', f.read(4))[0]
    if t == 4: return struct.unpack('>q', f.read(8))[0]
    if t == 5: return struct.unpack('>f', f.read(4))[0]
    if t == 6: return struct.unpack('>d', f.read(8))[0]
    if t == 7:
        n = struct.unpack('>i', f.read(4))[0]; return list(f.read(n))
    if t == 8:
        n = struct.unpack('>H', f.read(2))[0]; return f.read(n).decode('utf-8', 'replace')
    if t == 9:
        et = f.read(1)[0]; n = struct.unpack('>i', f.read(4))[0]
        return [_read(f, et) for _ in range(n)]
    if t == 10:
        d = {}
        while True:
            tt = f.read(1)[0]
            if tt == 0: return d
            name = _read(f, 8)
            d[name] = _read(f, tt)
    if t == 11:
        n = struct.unpack('>i', f.read(4))[0]; return list(struct.unpack('>%di' % n, f.read(4 * n)))
    if t == 12:
        n = struct.unpack('>i', f.read(4))[0]; return list(struct.unpack('>%dq' % n, f.read(8 * n)))
    raise ValueError('bad tag %d' % t)

def load(path):
    with gzip.open(path, 'rb') as f:
        t = f.read(1)[0]; _read(f, 8)
        return _read(f, t)

if __name__ == '__main__':
    d = load(sys.argv[1])
    print(json.dumps({k: d.get(k) for k in sys.argv[2:]} if len(sys.argv) > 2 else d, indent=1, ensure_ascii=False)[:6000])
