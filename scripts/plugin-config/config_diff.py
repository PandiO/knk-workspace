#!/usr/bin/env python3
"""Compare a server's plugin config.yml with the default config.yml inside a KnightsAndKings jar.

The plugin writes config.yml only when a server has none (saveDefaultConfig), so keys added by a
new build never reach an existing server file. This lists them, so they can be pasted by hand.
See knk-workspace docs/guides/admin/plugin-configuration.md section 2.

Usage:
  python3 config_diff.py <jar default config.yml> <server config.yml>
  unzip -p KnightsAndKings.jar config.yml > jar-config.yml   # gets the jar's default file

Prints keys missing on the server (paste them) and keys only on the server (removed from the
plugin, or a typo). It does not see a changed default: the server's value is kept on purpose,
so read the changelog's "Admin steps" for those. Needs PyYAML (pip install pyyaml).
"""
import sys

import yaml


def leaves(node, prefix=""):
    """Flatten a YAML mapping into {"a.b.c": value}; an empty mapping counts as one value."""
    out = {}
    if isinstance(node, dict) and node:
        for key, value in node.items():
            path = f"{prefix}.{key}" if prefix else str(key)
            out.update(leaves(value, path))
    else:
        out[prefix] = node
    return out


def load(path):
    with open(path, encoding="utf-8") as f:
        return leaves(yaml.safe_load(f) or {})


def covered(key, other):
    """True when other has the key, or a key below it (so an emptied section isn't reported twice)."""
    return key in other or any(k.startswith(key + ".") for k in other)


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    jar, server = load(argv[1]), load(argv[2])
    missing = sorted(k for k in jar if not covered(k, server))
    extra = sorted(k for k in server if not covered(k, jar))
    print(f"Missing on the server ({len(missing)}): paste these from the jar's file, with their comments")
    for k in missing:
        print(f"  {k}: {jar[k]!r}")
    print(f"\nOnly on the server ({len(extra)}): removed from the plugin, or a typo; check the changelog")
    for k in extra:
        print(f"  {k}")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
