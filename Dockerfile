FROM nvcr.io/nvidia/nvhpc:24.11-devel-cuda12.6-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# OpenFOAM/SPUMA build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    flex \
    bison \
    cmake \
    ninja-build \
    zlib1g-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libreadline-dev \
    libncurses-dev \
    libxt-dev \
    libopenmpi-dev \
    openmpi-bin \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Obtain SPUMA
WORKDIR /opt
RUN git clone https://github.com/sbryngelson/spuma.git

WORKDIR /opt/spuma

# Configure SPUMA/OpenFOAM for NVIDIA compiler
RUN sed -i 's/^WM_COMPILER=.*/WM_COMPILER=Nvidia/' etc/bashrc && \
    sed -i 's/^FOAM_SIGFPE=.*/FOAM_SIGFPE=false/' etc/bashrc

# H200 = Hopper, compute capability 9.0
ENV have_cuda=true
ENV NVARCH=90

# Diagnostic: locate NVIDIA HPC SDK and CUDA
RUN nvc++ --version && \
    echo "PATH=$PATH" && \
    which nvc++ && \
    which nvcc || true && \
    find /opt/nvidia -maxdepth 5 -type f -name nvcc -print || true && \
    find /usr/local -maxdepth 3 -type f -name nvcc -print || true

# Diagnostic: verify compiler and CUDA installation
RUN nvc++ --version && \
    ls -la /usr/local/cuda/bin/nvcc

# Compile SPUMA
RUN /bin/bash -lc 'source /opt/spuma/etc/bashrc && ./Allwmake -j 2'

# Automatically initialise SPUMA in interactive shells
RUN echo 'source /opt/spuma/etc/bashrc' >> /root/.bashrc

WORKDIR /workspace

CMD ["/bin/bash"]