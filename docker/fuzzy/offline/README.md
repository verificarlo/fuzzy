# Offline builds on a Slurm cluster

These adapters let the release recipes build on compute nodes without
Internet access. They use the same recipes, package sources, compiler flags
and complete image tests as the networked build. Stage sources and Python
build dependencies on a networked machine, verify their hashes, then bind
the bundle read-only during the compute job. The bundle and adapter tools
are not included in the final image.

On a networked machine with CPython 3.12 and pip:

```bash
python3 docker/fuzzy/offline/prepare.py /path/to/bundle
cd /path/to/bundle && sha256sum -c SHA256SUMS
```

The preparation script stages the package versions in the v2.7.0 recipes;
custom recipe versions require preparing the corresponding inputs too.

The compute job also needs OCI archives of the base image and uv. First
build the level's Verificarlo base with its released Dockerfile and
`--build-arg PRISM_ARCH=x86-64-v4`. Then prepare the apt dependencies and uv:

```bash
podman build --format docker --target base \
  --build-arg BASE=localhost/verificarlo/verificarlo:v2.7.0-avx512 \
  --build-arg MARCH=x86-64-v4 \
  -t localhost/fuzzy-offline-base:v4 -f docker/fuzzy/Dockerfile .
podman save --format oci-archive -o base-v4.oci.tar localhost/fuzzy-offline-base:v4
podman save --format oci-archive -o uv.oci.tar ghcr.io/astral-sh/uv:0.12.21
```

This `base` target installs the build dependencies but does not execute the
instrumented packages, so it can be prepared on an AVX2 host. The full v4
package build and tests must run on an AVX-512 node. The prepared base also
contains all runtime apt dependencies; the offline apt adapter verifies
they are installed rather than trying a network download.

Transfer the source checkout, bundle and OCI archives to cluster scratch.
In a Slurm allocation with sufficient memory and node-local storage, load
Podman and run:

```bash
export FUZZY_OFFLINE_BUNDLE=/scratch/USER/fuzzy/bundle
export FUZZY_OFFLINE_STORAGE="$SLURM_TMPDIR/fuzzy-podman"
export JOBS=2 TORCH_BUILD_JOBS=8
engine="$PWD/docker/fuzzy/offline/podman.sh"
"$engine" load -i /scratch/USER/fuzzy/base-v4.oci.tar
"$engine" tag localhost/fuzzy-offline-base:v4 localhost/verificarlo/verificarlo:v2.7.0-avx512
"$engine" load -i /scratch/USER/fuzzy/uv.oci.tar
srun --cpu-bind=cores docker/fuzzy/build.sh v4 "$engine"
"$engine" save --format oci-archive -o /scratch/USER/fuzzy/v4.oci.tar \
  verificarlo/fuzzy:v2.7.0-x86-64-v4
```

Choose the Slurm account, CPU count, memory and wall time for your site.
Use the allocated CPU affinity for compiler subprocesses. The engine
adapter uses node-local container storage, disables build networking and
refuses registry pulls. `overlay.ignore_chown_errors=true` supports sites
that provide only a single rootless UID mapping.

The normal Dockerfile is transformed only to prepend temporary environment
settings to its shell `RUN` instructions. The final image keeps the normal
runtime environment. Offline git clones come from the staged source trees;
other git operations remain local and cannot fetch remote transports.

## A CI controller for Slurm

A trusted runner can act as the controller while the compilation and tests
run on Rorqual. Set these variables in that runner's environment:

```bash
export FUZZY_SLURM_HOST=rorqual
export FUZZY_SLURM_ROOT=/scratch/USER/fuzzy
export FUZZY_SLURM_ACCOUNT=ACCOUNT
export FUZZY_CONTAINER_ENGINE=podman
```

The root directory must already contain `bundle/`, `base-v4.oci.tar` and
`uv.oci.tar`. Authenticate SSH, including the site's MFA, before starting the
controller. The v4 workflow then uses `remote-build.py`: it stages a clean
source revision, submits the Slurm job, observes that exact job handle and
imports its checksum-verified OCI archive after all checks pass. Source
snapshots come from `git archive`, are published atomically, and remain
unchanged when several levels use the same revision. The node-local copy
preserves contents and mode bits without copying host ACLs or xattrs.
A repeated controller invocation resumes the handle stored on the
submission host.

The controller also uses `checkpoint-vN.tar` under that root. Completed
stages are restored from a checksum-verified cache and saved when the job
exits, including after a later check fails. Source changes still invalidate
the corresponding Dockerfile stages; the normal image tests remain required.

This lets the `avx512` runner label describe an AVX-512 build capability
provided by Slurm. The controller itself can run on an AVX2 workstation;
it never executes the v4 binaries. A temporary runner may be configured
for one job, so no persistent service or compilation on a login node is
required. Publishing uses the controller's selected container engine.
