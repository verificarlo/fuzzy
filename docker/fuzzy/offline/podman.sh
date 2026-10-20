#!/bin/bash
# Engine adapter: FUZZY_OFFLINE_BUNDLE and FUZZY_OFFLINE_STORAGE are required.
set -euo pipefail
bundle=${FUZZY_OFFLINE_BUNDLE:?Set FUZZY_OFFLINE_BUNDLE to the prepared bundle}
storage=${FUZZY_OFFLINE_STORAGE:?Set FUZZY_OFFLINE_STORAGE to node-local storage}
command=${1:?podman subcommand required}
shift
options=(--root "$storage/storage" --runroot "$storage/run"
    --storage-opt overlay.ignore_chown_errors=true)
if [ "$command" = build ]; then
    here=$(cd "$(dirname "$0")" && pwd)
    arguments=()
    while [ $# -gt 0 ]; do
        if [ "$1" = -f ]; then
            generated=$(mktemp)
            python3 "$here/dockerfile.py" "$2" "$generated"
            arguments+=(-f "$generated")
            shift 2
        else
            arguments+=("$1")
            shift
        fi
    done
    exec podman "${options[@]}" build --format docker --jobs "${JOBS:-2}" \
        --pull=never --network=none --volume "$bundle:/opt/fuzzy-offline:ro" "${arguments[@]}"
fi
exec podman "${options[@]}" "$command" "$@"
