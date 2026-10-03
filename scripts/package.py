#!/usr/bin/env python3
"""Build the release zips.

Usage: python3 scripts/package.py <version> [output-dir]

Creates, in the output directory (default: dist):

  Keldurn-Addons-<version>.zip   every addon folder at the root of the zip, so it
                                 can be extracted straight into the game's
                                 AddOns folder
  <Addon>-<version>.zip          one zip per addon, same layout

Runs the same locally and in the release workflow. Only the standard library.
"""
import os
import re
import subprocess
import sys
import time
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDONS = os.path.join(ROOT, "AddOns")


def fail(message):
    sys.exit("error: " + message)


def commit_time():
    """Timestamp of the last commit, so the same commit gives the same zips."""
    try:
        out = subprocess.check_output(["git", "-C", ROOT, "log", "-1", "--format=%ct"], text=True)
        return time.gmtime(int(out.strip()))[:6]
    except Exception:
        return (2026, 1, 1, 0, 0, 0)


def addon_names():
    names = sorted(n for n in os.listdir(ADDONS) if os.path.isdir(os.path.join(ADDONS, n)))
    if not names:
        fail("no addon folders found in " + ADDONS)
    for name in names:
        # The game only loads a folder that contains a .toc with the same name
        if not os.path.isfile(os.path.join(ADDONS, name, name + ".toc")):
            fail("%s/%s.toc is missing" % (name, name))
    return names


def files_of(name):
    found = []
    for folder, dirs, files in os.walk(os.path.join(ADDONS, name)):
        dirs.sort()
        for f in sorted(files):
            path = os.path.join(folder, f)
            found.append(os.path.relpath(path, ADDONS).replace(os.sep, "/"))
    return found


def write_zip(path, names, when):
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        for name in names:
            for rel in files_of(name):
                info = zipfile.ZipInfo(rel, date_time=when)
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = 0o644 << 16
                with open(os.path.join(ADDONS, rel), "rb") as f:
                    z.writestr(info, f.read())


def check_zip(path, names):
    """Re-open a zip and make sure it has the layout the game needs."""
    with zipfile.ZipFile(path) as z:
        entries = set(z.namelist())
        bad = z.testzip()
    if bad:
        fail("corrupt entry %s in %s" % (bad, path))
    for name in names:
        if name + "/" + name + ".toc" not in entries:
            fail("%s: %s/%s.toc is not at the expected place" % (path, name, name))
    for entry in entries:
        if entry.split("/")[0] not in names:
            fail("%s: unexpected entry %s" % (path, entry))


def main():
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        sys.exit(__doc__)
    version = sys.argv[1]
    if not re.match(r"^[A-Za-z0-9][A-Za-z0-9._-]*$", version):
        fail("the version may only contain letters, digits, '.', '_' and '-'")
    out_dir = sys.argv[2] if len(sys.argv) == 3 else "dist"
    os.makedirs(out_dir, exist_ok=True)

    names = addon_names()
    when = commit_time()

    jobs = [("Keldurn-Addons-%s.zip" % version, names)]
    # '!OmniCC' -> 'OmniCC': GitHub does not keep '!' in release file names
    jobs += [("%s-%s.zip" % (n.lstrip("!"), version), [n]) for n in names]

    for filename, members in jobs:
        path = os.path.join(out_dir, filename)
        write_zip(path, members, when)
        check_zip(path, members)
        print("%-40s %7.1f KB  (%s)" % (filename, os.path.getsize(path) / 1024.0, ", ".join(members)))


if __name__ == "__main__":
    main()
