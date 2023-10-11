# RunPod Worker Comfy

> ComfyUI via API on [RunPod](https://www.runpod.io/) serverless

<!-- toc -->

- [Config](#config)
  * [Upload image to AWS S3](#upload-image-to-aws-s3)
- [Use the Docker image on RunPod](#use-the-docker-image-on-runpod)
- [Interact with your RunPod API](#interact-with-your-runpod-api)
  * [Health status](#health-status)
  * [Trigger the handler](#trigger-the-handler)
- [Build the image](#build-the-image)
- [Release](#release)
  * [Config: GitHub Action](#config-github-action)
- [Local testing](#local-testing)
  * [Test setup for Windows](#test-setup-for-windows)
- [Acknowledgements](#acknowledgements)

<!-- tocstop -->

---

This worker is using Ubuntu with CUDA drivers as it's base. It setups ComfyUI and makes it available via an runpod-compatible handler. The worker waits until the image was generated in ComfyUI, uploads the image to AWS S3 and provides the URL to the image as a response.

## Config

### Upload image to AWS S3

| Environment Variable       | Description                                             | Example                                    |
| -------------------------- | ------------------------------------------------------- | ------------------------------------------ |
| `BUCKET_ENDPOINT_URL`      | The endpoint URL of your S3 bucket.                     | `https://s3.amazonaws.com`                 |
| `BUCKET_ACCESS_KEY_ID`     | Your AWS access key ID for accessing the S3 bucket.     | `AKIAIOSFODNN7EXAMPLE`                     |
| `BUCKET_SECRET_ACCESS_KEY` | Your AWS secret access key for accessing the S3 bucket. | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |

## Use the Docker image on RunPod

* Create a [new template](https://runpod.io/console/serverless/user/templates) by clicking on `New Template` 
* In the dialog, configure:
  * Template Name: `runpod-worker-comfy` (it can be anything you want)
  * Container Image: `<dockerhub_username>/<repository_name>:tag`, in this case: `timpietruskyblibla/runpod-worker-comfy:1.0.0` (or `dev` if you want to have the latest, unreleased version)
  * Container Registry Credentials: You can leave everything as it is, as this repo is public
  * Container Disk: `20 GB`
  * Enviroment Variables: [Configure S3](#upload-image-to-aws-s3)
    * Note: You can also not configure it, the images will then stay in the worker. In order to have them stored permanently, [we have to add the network volume](https://github.com/blib-la/runpod-worker-comfy/issues/1)
* Click on `Save Template`
* Navigate to [`Serverless > Endpoints`](https://www.runpod.io/console/serverless/user/endpoints) and click on `New Endpoint`
* In the dialog, configure:
  * Endpoint Name: `comfy`
  * Select Template: `runpow-worker-comfy` (or what ever name you gave your template)
  * Active Workers: `0` (what ever makes sense for you)
  * Max Workers: `3` (what ever makes sense for you)
  * Idle Timeout: `5` (you can leave the default)
  * Flash Boot: `enabled` (doesn't cost more, but provides faster boot of our worker, which is good)
  * Advanced: Leave the defaults
  * Select a GPU that has some availability
  * GPUs/Worker: `1`
* Click `deploy`
* Your endpoint will be created, you can click on it to see the dashboard

## Interact with your RunPod API

* In the [User Settings](https://www.runpod.io/console/serverless/user/settings) click on `API Keys` and then on the `API Key` button
* Save the generated key somewhere, as you will not be able to see it again when you navigate away from the page
* Use cURL or any other tool to access the API using the API key and your Endpoint-ID:
  * Replace `<api_key>` with your key
  * Replace `<endpoint_id>` with the ID of the endpoint, you find that when you click on your endpoint, it's part of the URLs shown at the bottom of the first box

### Health status

```bash
curl -H "Authorization: Bearer <api_key>" https://api.runpod.ai/v2/<endpoint_id>/health
```

### Generate an image

You can ether create a new job async by using /run or a sync by using runsync. The example here is using a sync job and waits until the response is delivered. 

The API expects

```bash
curl -X POST -H "Authorization: Bearer <api_key>" -H "Content-Type: application/json" -d '{"input":{"prompt":{"prompt":{"3":{"inputs":{"seed":123123123123123,"steps":20,"cfg":8,"sampler_name":"euler","scheduler":"normal","denoise":1,"model":["4",0],"positive":["6",0],"negative":["7",0],"latent_image":["5",0]},"class_type":"KSampler"},"4":{"inputs":{"ckpt_name":"sd_xl_base_1.0.safetensors"},"class_type":"CheckpointLoaderSimple"},"5":{"inputs":{"width":512,"height":512,"batch_size":1},"class_type":"EmptyLatentImage"},"6":{"inputs":{"text":"beautiful scenery nature glass bottle landscape, , purple galaxy bottle,","clip":["4",1]},"class_type":"CLIPTextEncode"},"7":{"inputs":{"text":"text, watermark","clip":["4",1]},"class_type":"CLIPTextEncode"},"8":{"inputs":{"samples":["3",0],"vae":["4",2]},"class_type":"VAEDecode"},"9":{"inputs":{"filename_prefix":"ComfyUI","images":["8",0]},"class_type":"SaveImage"}}}}}' https://api.runpod.ai/v2/<endpoint_id>/runsync

# {"delayTime":2188,"executionTime":2297,"id":"sync-c0cd1eb2-068f-4ecf-a99a-55770fc77391-e1","output":{"message":"https://bucket.s3.region.amazonaws.com/10-23/sync-c0cd1eb2-068f-4ecf-a99a-55770fc77391-e1/c67ad621.png","status":"success"},"status":"COMPLETED"}
```

## Build the image

- You can build the image locally: `docker build -t timpietruskyblibla/runpod-worker-comfy:1.0.0 .`

## Release

There are two workflows, one creates a dev release and the other one creates an actual release, based on the tags created on GitHub

### Config: GitHub Action

This is only relevant if you want to publish the image to Docker Hub via a GitHub action.

| Configuration Variable | Description                                                  | Example Value         |
| ---------------------- | ------------------------------------------------------------ | --------------------- |
| `DOCKERHUB_USERNAME`   | Your Docker Hub username.                                    | `your-username`       |
| `DOCKERHUB_TOKEN`      | Your Docker Hub token for authentication.                    | `your-token`          |
| `DOCKERHUB_REPO`       | The repository on Docker Hub where the image will be pushed. | `timpietruskyblibla`  |
| `DOCKERHUB_IMG`        | The name of the image to be pushed to Docker Hub.            | `runpod-worker-comfy` |

## Local testing

* Make sure you have Python >= 3.10
* Install the dependencies: `pip install -r requirements.txt`

Then you can run the handler: `python src/rp_handler.py`

If you want to run the Docker container, then you can use: `docker-compose up`

Both will use the data from [test_input.json](./test_input.json).

### Test setup for Windows

**Note**: Our hope was that we can use this Docker Image with Docker Desktop on Windows. But regardless what we did, it was not possible. So we decided to use Ubuntu as part of WSL (Windows Subsystem for Linux) inside of Windows. This works without any problems, but only if you don't run Docker on Windows itself.

To run the Docker image on Windows, we need to have WSL2 and a Linux distro (like Ubuntu) installed on Windows.

- Follow the [guide on how to get WSL2 and Linux installed in Windows](https://ubuntu.com/tutorials/install-ubuntu-on-wsl2-on-windows-11-with-gui-support#1-overview) to install Ubuntu
  - You can skip the "Install and use a GUI package" part as we don't need a GUI

* When Ubuntu is installed, you have to login to Ubuntu in the terminal: `wsl -d Ubuntu`
* Update the packages: `sudo apt update`
* [Install Docker in Ubuntu](https://docs.docker.com/engine/install/ubuntu/) & then install docker-compose `sudo apt-get install docker-compose`
* [Install the NVIDIA Toolkit in Ubuntu](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#configuring-docker) and create the `nvidia` runtime

- [Enable GPU acceleration on Ubuntu on WSL2 to use NVIDIA CUDA](https://ubuntu.com/tutorials/enabling-gpu-acceleration-on-ubuntu-on-wsl2-with-the-nvidia-cuda-platform#1-overview)

  - For the step "Install the appropriate Windows vGPU driver for WSL": If you already have your GPU driver installed on Windows, you can skip this

- Add your user to the `docker` group, so that you can use Docker without `sudo`: `sudo usermod -aG docker $USER`

## Acknowledgements

* Thanks to [Justin Merrell](https://github.com/justinmerrell) from RunPod for [worker-1111](https://github.com/runpod-workers/worker-a1111), which was used to get inspired on how to create this worker
* Thanks to [Ashley Kleynhans](https://github.com/ashleykleynhans) for [runpod-worker-a1111](https://github.com/ashleykleynhans/runpod-worker-a1111), which was used to get inspired on how to create this worker
* Thanks to [comfyanonymous](https://github.com/comfyanonymous) for creating [ComfyUI](https://github.com/comfyanonymous/ComfyUI), which provides such an awesome API to interact with Stable Diffusion