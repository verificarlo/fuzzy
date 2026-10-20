#!/usr/bin/env python3
"""Add offline RUN adapters without persisting their environment in an image."""
from pathlib import Path
import sys

source, destination = map(Path, sys.argv[1:])
prefix = ("export PATH=/opt/fuzzy-offline/bin:$PATH "
          "UV_OFFLINE=1 PIP_NO_INDEX=1 PIP_FIND_LINKS=/opt/fuzzy-offline/wheels; ")
destination.write_text("".join(
    "RUN " + prefix + line[4:] if line.startswith("RUN ") else line
    for line in source.read_text().splitlines(keepends=True)))
