# rocm-torch — Minimal PyTorch + ROCm base image for AMD RDNA 4 GPUs
# No ROCm SDK required — PyTorch wheels bundle their own runtime.
# https://github.com/CarbonNeuron/rocm-torch

ARG UBUNTU_VERSION=24.04
ARG PYTHON_VERSION=3.12
ARG TORCH_VERSION=2.12.0
ARG TORCHVISION_VERSION=0.27.0
ARG TORCHAUDIO_VERSION=2.11.0
ARG ROCM_VERSION=7.2

FROM ubuntu:${UBUNTU_VERSION} AS base

ARG PYTHON_VERSION
ARG TORCH_VERSION
ARG TORCHVISION_VERSION
ARG TORCHAUDIO_VERSION
ARG ROCM_VERSION

LABEL org.opencontainers.image.title="rocm-torch" \
      org.opencontainers.image.description="Minimal PyTorch + ROCm for AMD RDNA 4 GPUs - no ROCm SDK needed" \
      org.opencontainers.image.source="https://github.com/CarbonNeuron/rocm-torch" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.authors="CarbonNeuron" \
      torch.version="${TORCH_VERSION}" \
      rocm.version="${ROCM_VERSION}" \
      python.version="${PYTHON_VERSION}"

# Python (deadsnakes PPA) + minimal runtime deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get install -y --no-install-recommends \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-venv \
        python${PYTHON_VERSION}-dev \
        python3-pip \
        libatomic1 \
        libgl1 \
        libglib2.0-0 && \
    apt-get purge -y software-properties-common && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# PyTorch stack — wheels bundle their own ROCm user-space runtime
RUN pip${PYTHON_VERSION} install \
    --use-pep517 --break-system-packages --no-cache-dir \
    torch==${TORCH_VERSION} \
    torchvision==${TORCHVISION_VERSION} \
    torchaudio==${TORCHAUDIO_VERSION} \
    --index-url https://download.pytorch.org/whl/rocm${ROCM_VERSION}

# Persist ROCm JIT kernel caches across container restarts.
# First run compiles kernels for your GPU (~60s), subsequent runs are instant.
VOLUME /root/.cache/comgr
VOLUME /root/.cache/miopen
VOLUME /root/.config/miopen
