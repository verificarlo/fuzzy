#!/bin/bash
# Run the complete image checks with the CPUID and ISA of an older processor.
# Usage: run-sde.sh v1|v2|v3 IMAGE SDE_DIRECTORY [podman|docker]
set -euo pipefail
level=${1:?usage: run-sde.sh v1|v2|v3 IMAGE SDE_DIRECTORY [podman|docker]}
image=${2:?IMAGE is required}
sde=$(realpath "${3:?SDE_DIRECTORY is required}")
engine=${4:-podman}
case $level in
    v1) chip=(-cpuid_in /opt/fuzzy-checks/docker/fuzzy/tests/x86-64-v1.cpuid -chip_check_cpuid) ;;
    v2) chip=(-nhm) ;;
    v3) chip=(-hsw) ;;
    *) echo 'SDE checks apply to v1, v2 and v3' >&2; exit 2 ;;
esac
[ -x "$sde/sde64" ] || { echo "no sde64 in $sde" >&2; exit 2; }
root=$(cd "$(dirname "$0")/../../.." && pwd)
args=(--rm --cap-add=SYS_PTRACE --security-opt seccomp=unconfined
    -v "$sde:/opt/intel-sde:ro" -v "$root:/opt/fuzzy-checks:ro")
if [ "$engine" = podman ]; then args+=(--security-opt label=disable); fi
if [ -n "${FUZZY_OFFLINE_BUNDLE:-}" ]; then
    args+=(-v "$FUZZY_OFFLINE_BUNDLE:/opt/fuzzy-offline:ro" -e FUZZY_OFFLINE=1)
fi
"$engine" run "${args[@]}" "$image" bash -euc '
    if [ "${FUZZY_OFFLINE:-}" = 1 ]; then
        export PATH=/opt/fuzzy-offline/bin:$PATH PIP_NO_INDEX=1 PIP_FIND_LINKS=/opt/fuzzy-offline/wheels
    fi
    mkdir -p /tmp/fuzzy-tests
    cp /opt/fuzzy-checks/docker/fuzzy/tests/* /tmp/fuzzy-tests/
    cp /opt/fuzzy-checks/docker/fuzzy/recipes/wheeltool.py /tmp/fuzzy-tests/
    cp /opt/fuzzy-checks/docker/resources/lapack/test_blas.c /tmp/fuzzy-tests/
    cp /opt/fuzzy-checks/docker/resources/numpy-sanity-check.py /tmp/fuzzy-tests/
    # SDE must not inherit the instrumented libm before it sets up its own
    # runtime. env restores the preload only inside the emulated application.
    preload=$LD_PRELOAD
    unset LD_PRELOAD
    exec /opt/intel-sde/sde64 "${@:2}" -chip_check_die -follow_subprocess -- \
        /usr/bin/env LD_PRELOAD="$preload" /bin/bash /tmp/fuzzy-tests/run.sh "x86-64-$1"
' bash "$level" "${chip[@]}"
