#!/usr/bin/python3
"""Expose Meson response-file arguments to the Verificarlo driver."""
import os
from pathlib import Path
import shlex
import sys

language, *arguments = sys.argv[1:]
frontend = {"c": "clang", "c++": "clang++"}[language]
driver = {"c": "verificarlo-c", "c++": "verificarlo-c++"}[language]


def expand(arguments, parents=()):
    result = []
    for argument in arguments:
        if argument.startswith("@"):
            path = Path(argument[1:]).resolve()
            if path in parents:
                raise SystemExit(f"recursive compiler response file: {path}")
            result.extend(expand(shlex.split(path.read_text()), (*parents, path)))
        else:
            result.append(argument)
    return result


arguments = expand(arguments)
if arguments == ["--version"]:
    os.execvp(frontend, [frontend, *arguments])
if "-c" not in arguments:
    # Keep backend/dispatch options visible so the driver links PRISM even
    # when Meson puts every linker argument in a response file.
    arguments = [arg for arg in arguments
                 if arg != "--inst-fma" and not arg.startswith("--exclude-file=")]
os.execvp(driver, [driver, *arguments])
