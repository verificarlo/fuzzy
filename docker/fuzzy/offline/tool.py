#!/usr/bin/python3
"""Offline adapters used only inside an explicitly staged build."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile

root = Path("/opt/fuzzy-offline")
tool = Path(sys.argv[0]).name
arguments = sys.argv[1:]
index = json.loads((root / "sources.json").read_text())

if tool == "git" and arguments and arguments[0] == "clone":
    url, destination = arguments[-2:]
    ref = arguments[arguments.index("--branch") + 1]
    source = root / index[url + "@" + ref]["file"]
    Path(destination).mkdir(parents=True)
    with tarfile.open(source) as archive:
        archive.extractall(destination, filter="data")
elif tool == "wget":
    if len(arguments) != 2 or arguments[0] != "-qO-":
        raise SystemExit(f"Unsupported offline wget call: {arguments}")
    source = root / index[arguments[1]]["file"]
    with source.open("rb") as stream:
        import shutil
        shutil.copyfileobj(stream, sys.stdout.buffer)
elif tool == "apt-get":
    # The prepared base contains the union of the builder and runtime apt
    # dependencies. update needs no network; install verifies completeness.
    if "update" in arguments:
        print("Offline build: using the staged apt package set", file=sys.stderr)
    elif "install" in arguments:
        packages = [arg for arg in arguments[arguments.index("install") + 1:]
                    if not arg.startswith("-")]
        for package in packages:
            result = subprocess.check_output(
                ["dpkg-query", "-W", "-f=${Status}", package], text=True)
            if result != "install ok installed":
                raise SystemExit(f"Missing staged apt dependency: {package}")
    else:
        raise SystemExit(f"Unsupported offline apt-get call: {arguments}")
elif tool == "uv":
    if arguments[:2] == ["pip", "install"]:
        arguments[2:2] = ["--offline", "--no-index", "--find-links", str(root / "wheels")]
    elif arguments[:1] == ["venv"] and "--seed" in arguments:
        arguments[1:1] = ["--offline", "--no-index", "--find-links", str(root / "wheels")]
    os.execv("/usr/local/bin/uv", ["uv", *arguments])
else:
    # git describe/status/submodule checks remain real git commands. No fetch
    # is allowed to fall through to a network transport on the compute node.
    if tool != "git":
        raise SystemExit(f"Unknown offline tool: {tool}")
    os.environ["GIT_ALLOW_PROTOCOL"] = "file"
    os.execv("/usr/bin/git", ["git", *arguments])
