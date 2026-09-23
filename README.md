# SPUMA H200

Docker environment for building and running [SPUMA](https://github.com/sbryngelson/spuma), a GPU-enabled OpenFOAM implementation, on NVIDIA H200 GPUs.

The Docker image is built automatically using GitHub Actions and published to the GitHub Container Registry (GHCR). The resulting image can then be deployed to an H200 through platforms such as Run:ai without recompiling SPUMA for each workload.

## Environment

The image currently uses:

- Ubuntu 22.04
- NVIDIA HPC SDK 24.11
- CUDA 12.6
- SPUMA / OpenFOAM
- NVIDIA HPC C++ compiler (`nvc++`)
- NVIDIA Hopper compute capability 9.0 (`cc90`)
- OpenMPI

The base image is:

```text
nvcr.io/nvidia/nvhpc:24.11-devel-cuda12.6-ubuntu22.04
```

## Container Image

The latest successful build is published to:

```text
ghcr.io/ice-kold/spuma-h200:latest
```

Pull the image with:

```bash
docker pull ghcr.io/ice-kold/spuma-h200:latest
```

## Running Locally

A host with an NVIDIA GPU, compatible NVIDIA driver, Docker, and the NVIDIA Container Toolkit is required.

Run the container interactively with GPU access:

```bash
docker run --rm -it --gpus all \
  ghcr.io/ice-kold/spuma-h200:latest
```

Once inside the container, verify that the GPU is available:

```bash
nvidia-smi
```

The SPUMA/OpenFOAM environment is automatically sourced when an interactive Bash shell starts.

Useful checks include:

```bash
echo $WM_COMPILER
echo $NVARCH
which nvc++
```

The H200 should use:

```text
NVARCH=90
```

corresponding to NVIDIA Hopper compute capability 9.0.

## Running a CFD Case

Simulation cases should normally remain separate from the Docker image.

A standard OpenFOAM case might contain:

```text
case/
├── 0/
├── constant/
│   └── polyMesh/
└── system/
    ├── controlDict
    ├── fvSchemes
    └── fvSolution
```

Mount a case into `/workspace` when starting the container:

```bash
docker run --rm -it --gpus all \
  -v /path/to/case:/workspace \
  ghcr.io/ice-kold/spuma-h200:latest
```

Then, inside the container:

```bash
cd /workspace
```

The required SPUMA/OpenFOAM solver can then be executed from the case directory.

## Building

The Docker image is built automatically using GitHub Actions whenever changes are pushed to the `main` branch.

## SPUMA Compilation

SPUMA is configured to use the NVIDIA HPC compiler:

```text
WM_COMPILER=Nvidia
```

CUDA support is enabled with:

```text
have_cuda=true
```

The target GPU architecture is:

```text
NVARCH=90
```

which corresponds to NVIDIA Hopper GPUs including the H100 and H200.

Because the GitHub Actions build runner does not have an NVIDIA GPU or driver available for CUDA version detection, the NVIDIA compiler is explicitly configured to use CUDA 12.6.

The relevant compiler target is:

```text
-gpu=cc90,cuda12.6
```

This specifies:

```text
cc90       -> NVIDIA Hopper compute capability 9.0
cuda12.6   -> CUDA 12.6 toolchain
```

SPUMA is then compiled using:

```bash
./Allwmake -j 2
```

The resulting compiled binaries are stored inside the Docker image.

## Run:ai

The pre-built container can be used as the image for a Run:ai workload:

```text
ghcr.io/ice-kold/spuma-h200:latest
```

The intended deployment architecture is:

```text
GitHub
   │
   │ source + Dockerfile
   ▼
GitHub Actions
   │
   │ compile SPUMA
   ▼
GHCR
   │
   │ container image
   ▼
Run:ai
   │
   │ allocate GPU
   ▼
NVIDIA H200
   │
   ▼
SPUMA CFD simulation
```

## Notes

SPUMA is an external project and is not maintained by this repository.

SPUMA source:

```text
https://github.com/sbryngelson/spuma
```

This repository provides a reproducible container build targeting NVIDIA H200/Hopper hardware.
