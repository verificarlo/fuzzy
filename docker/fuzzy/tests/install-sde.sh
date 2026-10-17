#!/bin/bash
# Pinned Intel SDE archive for the image compatibility checks.
set -euo pipefail
dest=${1:?usage: install-sde.sh DESTINATION}
archive=$(mktemp)
trap 'rm -f "$archive"' EXIT
curl --fail --location --retry 3 \
    https://downloadmirror.intel.com/924984/sde-external-10.13.1-2026-07-28-lin.tar.xz \
    -o "$archive"
printf '%s  %s\n' 94e97d623fec54385686e1e7ba65ebc9941748c05ee451423948334892bf2b50 "$archive" | sha256sum -c -
mkdir -p "$dest"
tar xJf "$archive" --strip-components=1 -C "$dest"
