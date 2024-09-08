# pwnbox

This is wrapper around various `Docker` commands to create a Linux environment useful for CTF. `pwnbox` will create a container that is setup with many tools, is run with `--privileged` to enable certain behaviors (namely GDB changing ASLR settings), and Docker `network` mode is set to `host` for easy ability to run networked programs. Additionally, the current working directory will be mounted to `/mount` inside the container, letting you share files with the host.

The default container image that `pwnbox` will use is built from the `Dockerfile` and is pushed to `ghcr.io/obarroncs/pwnbox`. There are two variants - the normal image, and a `full` image. The normal image is about 5GB, while the full image is about 15GB. The `full` image has a bunch of cross-compilers installed in it, which take up the 10GB. By default, the normal image is used. See notes below to change which image is used.

A variant for `wsl` is also built - the [filesystem can be exported and used to install a `wsl` distro](#create-wsl-image-from-the-container)!

## Install
Cloned this repository and add the `bin` folder to your path!
```sh
# This will clone the repo to the ~/pwnbox folder. You can change this location, but make sure to set the PATH variable accordingly.
git clone https://github.com/OBarronCS/pwnbox.git ~/pwnbox
```
#### bash
```sh
echo "export PATH="$HOME/pwnbox/bin:$PATH" >> ~/.bashrc
```
#### zsh
```sh
echo "export PATH="$HOME/pwnbox/bin:$PATH" >> ~/.zshrc
```

## Usage

### Create a pwnbox
This command will create a container with a given name - `ctf` in this case
```sh
pwnbox create ctf
```

### Enter an existing pwnbox
```sh
pwnbox enter ctf [--image IMAGE_NAME]
# You can optionally pass an image name to override the use of the default image included in this repo
```
### Other
```sh
# Create a temporary instance - this will be removed once the terminal session ends
pwnbox temp

# Delete a pwnbox
pwnbox rm pwnbox-name

# List all pwnboxes
pwnbox list

# Update - this simply runs `git pull` for the repo
pwnbox update

# Pull the latest version of the pwnbox image from the GitHub Container Registry
pwnbox pull
```

### Config
```sh
# Print the current config
pwnbox config show

# Set the default image (the one used on pwnbox create)
pwnbox config set --image IMAGE
# Set the default image to the 5GB `pwnbox` image
pwnbox config set --use-slim
# Set the default image to the 15GB image with cross-compilers
pwnbox config set --use-full
```


## Development
### Manually build the image
```sh
# Base image
docker build . --target base -t pwnbox
# Optional build args:
#   --build-arg FULL_BUILD=true

# Image build for WSL
docker build . --target wsl -t pwnbox

# To use this local image with `pwnbox create`, run `pwnbox config set --image pwnbox`
```


## Create WSL image from the container
We can extract the root filesystem from the image and use it as a WSL distro!

You can head to the [releases page](https://github.com/OBarronCS/pwnbox/releases) to grab the files and skip straight to step 2 (the file name ends in `tar.gz`). To build and extract the filesystem locally, start at step 1.


```powershell
# Step 1 - extract the root filesystem
docker create --name wsl-temp pwnbox
# This will take multiple minutes, and it has no progress meter
docker export wsl-temp -o wsl_rootfs.tar
docker rm wsl-temp

# Optionally, gzip the tar file to create a compressed archive for sharing. In testing, this has reduced the size of the tarball to a third of the original size.
gzip -9 -v wsl_rootfs.tar

# Step 2 - create a WSL distro with the tar file!
wsl --import pwnbox "$HOME/wsl_pwnbox" wsl_rootfs.tar
# --import also accepts .tar.gz files

# Start the distro!
wsl -d pwnbox
# Give it a few seconds to become responsive, and you are ready to go!
# pwnbox is automatically added to the Windows Terminal profile
```

### Notes on WSL + Docker Desktop on Windows

Docker Desktop is known to take an unbounded amount of RAM on Windows. If you notice in Task Manager that the Docker daemon is taking an enormous amount of RAM, a reliable way to reclaim it is to go into a terminal and type `wsl --shutdown` (it cannot be stopped in Task Manager). This will end all WSL and Docker processes and reclaim the memory. This will also turn off Docker Desktop - you will need to re-open it to turn it back on.

Additionally, when developing and creating images, Docker Desktop will not free up memory to the OS even after deleting images or a `docker system prune`. To reclaim this disk space, you can do the following to resize the file system Docker uses:

```powershell
wsl --shutdown

diskpart
select vdisk file="C:\Users\{YourUser}\AppData\Local\Docker\wsl\data\ext4.vhdx"
attach vdisk readonly
# If you get an error that says "Disk in use", run "wsl --shutdown" again
compact vdisk
detach vdisk
exit
```

