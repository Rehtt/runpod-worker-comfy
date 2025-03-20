#!/bin/bash

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh


docker build -t rehtt/comfy-chroma-v14 . &&
docker push rehtt/comfy-chroma-v14 &&
shutdown now