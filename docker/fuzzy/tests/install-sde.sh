#!/bin/bash
# Pin 3-based SDE: 10.13.1 fails to follow Python's close_fds subprocesses.
set -euo pipefail
dest=${1:?usage: install-sde.sh DESTINATION}
archive=$(mktemp)
trap 'rm -f "$archive"' EXIT
curl --fail --location --retry 3 \
    https://downloadmirror.intel.com/859732/sde-external-9.58.0-2025-06-16-lin.tar.xz \
    -o "$archive"
printf '%s  %s\n' f849acecad4c9b108259c643b2688fd65c35723cd23368abe5dd64b917cc18c0 "$archive" | sha256sum -c -
mkdir -p "$dest"
tar xJf "$archive" --strip-components=1 -C "$dest"
