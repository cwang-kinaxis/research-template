# Base image: CUDA 12 + cuDNN on Ubuntu 22.04
FROM pytorch/pytorch:2.9.1-cuda12.6-cudnn9-runtime

# Avoid interactive prompts during package install
ENV DEBIAN_FRONTEND=noninteractive

# System deps + Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    git \
    wget \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Make `python` point to `python3`
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Upgrade pip
RUN python -m pip install --no-cache-dir --upgrade pip

# Optional: create a workspace
WORKDIR /workspace

# Optional: copy your requirements and install them
# (comment these lines out if you don't have a requirements.txt yet)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Default command: drop into a shell
CMD ["/bin/bash"]
