# pwnbox

This contains various scripts to setup a Linux environment useful for CTF. A Docker image is also built - this is a great pre-built image to use with [Seabox](https://github.com/OBarronCS/seabox)! A variant for `wsl` is also built - the [filesystem can be exported and used to install a `wsl` distro](#create-wsl-image-from-the-container)!

The pre-built Docker image created from the `Dockerfile` in this repo can be found at [`ghcr.io/obarroncs/pwnbox`](https://github.com/OBarronCS/pwnbox/pkgs/container/pwnbox). There are two variants - the normal image, and a `full` image. The normal image is about 5GB, while the full image is about 15GB. The `full` image has a bunch of cross-compilers installed in it, which take up the 10GB.

## Quick install
```sh
curl -LsSf obarroncs.github.io/pwnbox/apt.sh | bash
curl -LsSf obarroncs.github.io/pwnbox/user.sh | bash

# Lite install
sudo apt update -y && sudo apt install -y build-essential vim git tmux
curl -LsSf obarroncs.github.io/pwnbox/user.sh | bash -s -- lite
```

## Create WSL image from the container
We can extract the root filesystem from the container image and use it as a WSL distro!

### Ensure WSL is installed

If you haven't used WSL before, make sure it is installed by running this command. This will require a reboot to take effect.
```powershell
wsl --install --no-distribution
```

### Automated install
You can use this one-line PowerShell command to download the latest `.tar.gz` file from GitHub releases and install it as a distro on WSL. 

```powershell
# The downloaded file will go into PowerShell's current directory
cd $HOME/Downloads
# This is the PowerShell equivalent of "curl | bash"
iwr https://obarroncs.github.io/pwnbox/wsl.ps1 | iex
```

The script is being hosted on `GitHub Pages` through this repo and can be found [here](https://github.com/OBarronCS/pwnbox/blob/main/wsl.ps1).

### Manual
Alternatively, you can manually build the image locally, prepare it, and install it as a distro.

You can skip step 1 (building the image locally) by heading to the [releases page](https://github.com/OBarronCS/pwnbox/releases) to grab the files (the file name ends in `tar.gz`) and go straight to step 2 below. To build and extract the filesystem locally, start at step 1.

### Step 1 - extract the root filesystem
```powershell
# Build the image (make sure the repo is cloned)
docker build . -t pwnbox

# Create a temporary container with the image
docker create --name wsl-temp pwnbox

# Extract the root filesystem.
# This will take multiple minutes, and it has no progress meter.
docker export wsl-temp -o wsl_rootfs.tar

# Remove the temporary container
docker rm wsl-temp

# Optionally, gzip the tar file to create a compressed archive for sharing. In testing, this has reduced the size of the tarball to a third of the original size.
gzip -9 -v wsl_rootfs.tar
```
### Step 2 - create a WSL distro with the tar file!
Use the `wsl --import` command to create a distro from the tar file.

The first parameter is the name assigned to the new distro - in this example, we call it `pwnbox`.

The second parameter is the path where windows will create the WSL filesystem. You will never interact with this manually, so just place it somewhere, like in your home directory.

The third parameter is the path to the root filesystem `.tar` file that you want to import. `.tar.gz` files also work.
```sh
wsl --import pwnbox "$HOME/wsl_pwnbox" ./wsl_rootfs.tar.gz

# Start the distro!
wsl -d pwnbox
# Give it a few seconds to become responsive, and you are ready to go!
# pwnbox is automatically added to the Windows Terminal profile
```

## Development
### Manually build the image
```sh
# You can swap podman with docker below:
# Base image
sudo podman build . --target base -t pwnbox
# Optional build args:
#   --build-arg FULL_BUILD=true

# Image build for WSL
sudo podman build . --target wsl -t pwnbox

# Or, build with Docker and then pull the image so that Podman can see it:
sudo podman pull docker-daemon:pwnbox:latest

# To use this local image with `pwnbox create`, run `pwnbox config set --image pwnbox`
```

### Notes on WSL + Docker Desktop on Windows

Docker Desktop is known to take an unbounded amount of RAM on Windows. If you notice in Task Manager that the Docker daemon is taking an enormous amount of RAM, a reliable way to reclaim it is to go into a terminal and type `wsl --shutdown` (it cannot be stopped in Task Manager). This will end all WSL and Docker processes and reclaim the memory. This will also turn off Docker Desktop - you will need to re-open it to turn it back on.

Additionally, if you are developing and creating Docker images on Windows, Docker Desktop will not free up memory to the OS even after deleting images or a `docker system prune`. To reclaim this disk space, you can do the following to resize the file system Docker uses:

```powershell
wsl --shutdown

diskpart
select vdisk file="C:\Users\{YourUser}\AppData\Local\Docker\wsl\data\ext4.vhdx"
attach vdisk readonly
# If you get an error that says "Disk in use", run "wsl --shutdown" again in another terminal
compact vdisk
detach vdisk
exit
```


## Release guide
This repo uses GitHub actions to upload the container image to GitHub Container Registry. The workflow to upload the image and create a new release is triggered on tags.

Get latest tag number
```sh
git describe --tags --abbrev=0
```
Increment this. For example, if using the release number `2.1.13`, you can do:

```sh
git tag -a v2.1.13 -m "Release v2.1.13"
git push origin v2.1.13
```
