# ==============================================================================
# xv6-edr-mlfq Docker Environment
# Multi-arch support for building and running xv6 RISC-V Kernel & EDR Subsystem
# ==============================================================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install RISC-V Toolchain, QEMU RISC-V, Build Essentials & Python3
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc-riscv64-unknown-elf \
    binutils-riscv64-unknown-elf \
    qemu-system-misc \
    gdb-multiarch \
    python3 \
    python3-pip \
    git \
    make \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Default command: build and run unit tests
CMD ["make", "qemu"]
