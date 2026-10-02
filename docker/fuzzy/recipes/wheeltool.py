#!/usr/bin/env python3
"""Wheel helpers for the Fuzzy image, standard library only.

  wheeltool.py retag WHEEL LABEL OUTDIR [--requires REQ ...] [--drop-rpath DIR ...]
      Copy WHEEL to OUTDIR with the local version label LABEL
      (numpy-2.4.6 -> numpy-2.4.6+prism) and extra Requires-Dist lines.
      --drop-rpath removes the RUNPATH entries under DIR from the shared
      objects (with patchelf): a wheel must find its libraries through the
      selected build, not through the build it was linked against.

  wheeltool.py marker NAME VERSION OUTDIR
      Write an empty pure-Python wheel NAME==VERSION to OUTDIR. The image uses
      one, fuzzy-prism-runtime==<prism>+<level>, as a dependency of every
      prism wheel, so that a wheel built for one x86-64 level cannot be
      installed into an image of another.
"""

import argparse
import base64
import hashlib
import os
import re
import subprocess
import tempfile
import zipfile


def escape(name):
    """Distribution name as it appears in wheel and dist-info file names."""
    return re.sub(r"[-_.]+", "_", name).lower()


def record_line(path, data):
    digest = base64.urlsafe_b64encode(hashlib.sha256(data).digest()).rstrip(b"=")
    return f"{path},sha256={digest.decode()},{len(data)}"


def write_wheel(outdir, name, version, tag, files):
    """files: {archive path: (bytes, unix mode)}, without RECORD."""
    distinfo = f"{escape(name)}-{version}.dist-info"
    record = [record_line(path, data) for path, (data, _) in files.items()]
    record.append(f"{distinfo}/RECORD,,")
    files = dict(files)
    files[f"{distinfo}/RECORD"] = (("\n".join(record) + "\n").encode(), 0o644)
    os.makedirs(outdir, exist_ok=True)
    path = os.path.join(outdir, f"{escape(name)}-{version}-{tag}.whl")
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as whl:
        for arcname, (data, mode) in files.items():
            info = zipfile.ZipInfo(arcname, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = (mode or 0o644) << 16
            whl.writestr(info, data)
    print(path)


def drop_rpath(data, dirs):
    """Shared object data without the RUNPATH entries under dirs."""
    with tempfile.NamedTemporaryFile(suffix=".so") as so:
        so.write(data)
        so.flush()
        rpath = subprocess.run(
            ["patchelf", "--print-rpath", so.name], check=True, capture_output=True, text=True
        ).stdout.strip()
        kept = [e for e in rpath.split(":") if e and not any(e.startswith(d) for d in dirs)]
        if kept == [e for e in rpath.split(":") if e]:
            return data
        if kept:
            subprocess.run(["patchelf", "--set-rpath", ":".join(kept), so.name], check=True)
        else:
            subprocess.run(["patchelf", "--remove-rpath", so.name], check=True)
        with open(so.name, "rb") as patched:
            return patched.read()


def retag(wheel, label, outdir, requires, rpath_dirs):
    filename = os.path.basename(wheel)
    name, version, tag = re.match(r"([^-]+)-([^-]+)-(.+)\.whl$", filename).groups()
    if "+" in version:
        raise SystemExit(f"{filename} already has a local version")
    new_version = f"{version}+{label}"
    old_distinfo = f"{name}-{version}.dist-info/"
    new_distinfo = f"{name}-{new_version}.dist-info/"

    files = {}
    with zipfile.ZipFile(wheel) as whl:
        for info in whl.infolist():
            arcname = info.filename
            if arcname == old_distinfo + "RECORD":
                continue
            data = whl.read(info)
            if arcname.startswith(old_distinfo):
                arcname = new_distinfo + arcname[len(old_distinfo):]
                if arcname == new_distinfo + "METADATA":
                    data = edit_metadata(data, new_version, requires)
            elif rpath_dirs and re.search(r"\.so(\.|$)", arcname):
                data = drop_rpath(data, rpath_dirs)
            files[arcname] = (data, info.external_attr >> 16)
    write_wheel(outdir, name, new_version, tag, files)


def edit_metadata(data, version, requires):
    text = data.decode()
    headers, sep, body = text.partition("\n\n")
    headers = re.sub(r"^Version: .*$", f"Version: {version}", headers.rstrip("\n"), count=1, flags=re.M)
    headers += "".join(f"\nRequires-Dist: {req}" for req in requires)
    return (headers + "\n" + (sep[1:] + body if sep else "")).encode()


def marker(name, version, outdir):
    distinfo = f"{escape(name)}-{version}.dist-info"
    metadata = f"Metadata-Version: 2.1\nName: {name}\nVersion: {version}\n"
    wheel = (
        "Wheel-Version: 1.0\nGenerator: fuzzy wheeltool\n"
        "Root-Is-Purelib: true\nTag: py3-none-any\n"
    )
    files = {
        f"{distinfo}/METADATA": (metadata.encode(), 0o644),
        f"{distinfo}/WHEEL": (wheel.encode(), 0o644),
    }
    write_wheel(outdir, name, version, "py3-none-any", files)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("retag")
    p.add_argument("wheel")
    p.add_argument("label")
    p.add_argument("outdir")
    p.add_argument("--requires", action="append", default=[])
    p.add_argument("--drop-rpath", action="append", default=[])
    p = sub.add_parser("marker")
    p.add_argument("name")
    p.add_argument("version")
    p.add_argument("outdir")
    args = parser.parse_args()
    if args.command == "retag":
        retag(args.wheel, args.label, args.outdir, args.requires, args.drop_rpath)
    else:
        marker(args.name, args.version, args.outdir)


if __name__ == "__main__":
    main()
