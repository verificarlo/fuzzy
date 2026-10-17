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
