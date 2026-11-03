#!/usr/bin/env python3
"""Unit test of knk-deploy's source extraction (#210). Needs no root and no Docker.

    python3 scripts/nas-ops/stage-b/tests/test_extract_source.py

knk-deploy runs with umask 077. The archive's directories must still come out 0755 (readable for nginx in the web
image), files keep their 0644, and the unsafe-archive checks still refuse.
"""
import importlib.machinery
import importlib.util
import io
import os
import stat
import sys
import tarfile
import tempfile

sys.dont_write_bytecode = True  # the repo tracks a __pycache__ copy; leave it alone
HERE = os.path.dirname(os.path.abspath(__file__))
PROG = os.path.join(HERE, '..', 'knk-deploy')
results = []


def check(name, cond, detail=''):
    results.append(bool(cond))
    print(('PASS ' if cond else 'FAIL ') + name + (f'  [{detail}]' if detail and not cond else ''), flush=True)


def load():
    loader = importlib.machinery.SourceFileLoader('knk_deploy', PROG)
    spec = importlib.util.spec_from_loader('knk_deploy', loader)
    m = importlib.util.module_from_spec(spec)
    loader.exec_module(m)
    return m


def archive(path, entries):
    """Like `git archive --prefix=source/`: directory entries 0775, files 0664 (or as given)."""
    with tarfile.open(path, 'w:gz') as t:
        for name, kind, mode in entries:
            info = tarfile.TarInfo(name)
            info.mode = mode
            if kind == 'dir':
                info.type = tarfile.DIRTYPE
                t.addfile(info)
            elif kind == 'link':
                info.type = tarfile.SYMTYPE
                info.linkname = '/etc/passwd'
                t.addfile(info)
            else:
                data = b'x'
                info.size = len(data)
                t.addfile(info, io.BytesIO(data))


def mode(path):
    return stat.S_IMODE(os.lstat(path).st_mode)


def main():
    m = load()
    old = os.umask(0o077)  # as knk-deploy's main() and dispatch
    try:
        with tempfile.TemporaryDirectory() as tmp:
            src = os.path.join(tmp, 'web.tar.gz')
            archive(src, [
                ('source/', 'dir', 0o775),
                ('source/public/', 'dir', 0o775),
                ('source/public/brand/', 'dir', 0o775),
                ('source/public/brand/knk-shield.png', 'file', 0o664),
                ('source/public/favicon.ico', 'file', 0o664),
                ('source/scripts/', 'dir', 0o775),
                ('source/scripts/run.sh', 'file', 0o775),
                ('source/private/', 'dir', 0o700),
            ])
            dest = os.path.join(tmp, 'build')
            os.makedirs(dest, mode=0o700)
            m.extract_source(src, dest)
            s = os.path.join(dest, 'source')
            for d in ('', 'public', 'public/brand', 'scripts', 'private'):
                check(f'directory source/{d} is 0755', mode(os.path.join(s, d)) == 0o755, oct(mode(os.path.join(s, d))))
            check('files keep 0644', mode(os.path.join(s, 'public/brand/knk-shield.png')) == 0o644,
                  oct(mode(os.path.join(s, 'public/brand/knk-shield.png'))))
            check('executables keep 0755', mode(os.path.join(s, 'scripts/run.sh')) == 0o755, oct(mode(os.path.join(s, 'scripts/run.sh'))))
            check('the build folder itself stays 0700', mode(dest) == 0o700, oct(mode(dest)))

            bad = os.path.join(tmp, 'bad.tar.gz')
            archive(bad, [('source/', 'dir', 0o775), ('source/link', 'link', 0o777)])
            dest2 = os.path.join(tmp, 'build2')
            os.makedirs(dest2, mode=0o700)
            try:
                m.extract_source(bad, dest2)
                check('a link out of the tree is refused', False, 'extracted')
            except tarfile.FilterError:
                check('a link out of the tree is refused', True)

            outside = os.path.join(tmp, 'outside.tar.gz')
            archive(outside, [('source/', 'dir', 0o775), ('other/x', 'file', 0o664)])
            try:
                m.extract_source(outside, dest2)
                check('names outside source/ are refused', False, 'extracted')
            except m.Refused:
                check('names outside source/ are refused', True)
    finally:
        os.umask(old)
    print(f'{sum(results)}/{len(results)} passed')
    return 0 if all(results) else 1


if __name__ == '__main__':
    sys.exit(main())
