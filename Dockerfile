# Stage 1: Base image with common dependencies
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 as base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1 
# Speed up some cmake builds
ENV CMAKE_BUILD_PARALLEL_LEVEL=8

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
  python3.10 \
  python3-pip \
  git \
  wget \
  libgl1 \
  aria2 \
  && ln -sf /usr/bin/python3.10 /usr/bin/python \
  && ln -sf /usr/bin/pip3 /usr/bin/pip \
  && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install comfy-cli
RUN pip install comfy-cli

# Install ComfyUI
RUN /usr/bin/yes | comfy --workspace /comfyui install --cuda-version 11.8 --nvidia --version 0.2.7 --skip-manager

# Change working directory to ComfyUI
WORKDIR /comfyui


# Install runpod
RUN pip install runpod requests

# Support for the network volume
ADD src/extra_model_paths.yaml ./

# Go back to the root
WORKDIR /

# Add scripts
ADD src/start.sh src/restore_snapshot.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh /restore_snapshot.sh

# Optionally copy the snapshot file
ADD *snapshot*.json /

# Restore the snapshot to install custom nodes
RUN /restore_snapshot.sh

# Change working directory to ComfyUI
WORKDIR /comfyui

RUN git clone https://github.com/lodestone-rock/ComfyUI_FluxMod.git custom_nodes/ComfyUI_FluxMod
RUN mkdir -p models/clip && aria2c -s 8 -x 8 -k 100M -o models/clip/t5xxl_fp16.safetensors https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors
RUN mkdir -p models/vae && aria2c -s 8 -x 8 -k 100M -o models/vae/ae.safetensors https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors
RUN mkdir -p models/diffusion_models && aria2c -s 8 -x 8 -k 100M -o models/diffusion_models/chroma-unlocked-v15.safetensors https://huggingface.co/lodestones/Chroma/resolve/main/chroma-unlocked-v15.safetensors

# Start container
CMD ["/start.sh"]
