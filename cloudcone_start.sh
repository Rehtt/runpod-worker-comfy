#!/bin/bash

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

docker login

apt update && apt install tmux

dd if=/dev/zero of=/var/swapfile bs=1M count=4096
mkswap /var/swapfile
swapon /var/swapfile

tmux new-session -d -s mysession "docker build -t rehtt/runpod-worker-comfy:chroma-v14 . && docker push rehtt/runpod-worker-comfy:chroma-v14 && shutdown now"
