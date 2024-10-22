# pwnbox

This is wrapper around various `Docker` commands to create a Linux environment useful for CTF. `pwnbox` will create a container that is setup with many tools, is run with `--privileged` to enable certain behaviors (namely GDB changing ASLR settings), and Docker `network` mode is set to `host` for easy ability to run networked programs. Additionally, the current working directory will be mounted to `/mount` inside the container, letting you share files with the host.

The default container image that `pwnbox` will use is built from the `Dockerfile` in this repo. A pre-built version can be found at `ghcr.io/obarroncs/pwnbox`. There are two variants - the normal image, and a `full` image. The normal image is about 5GB, while the full image is about 15GB. The `full` image has a bunch of cross-compilers installed in it, which take up the 10GB. By default, the normal image is used. See notes below to change which image is used.

A variant for `wsl` is also built - the [filesystem can be exported and used to install a `wsl` distro](#create-wsl-image-from-the-container)!

## Install
Clone this repository and add the `bin` folder to your path!
```sh
# This will clone the repo to the ~/pwnbox folder. You can change this location, but make sure to set the PATH variable accordingly.
git clone https://github.com/OBarronCS/pwnbox.git ~/pwnbox
```
#### bash
```sh
echo 'export PATH="$HOME/pwnbox/bin:$PATH"' >> ~/.bashrc
```
#### zsh
```sh
echo 'export PATH="$HOME/pwnbox/bin:$PATH"' >> ~/.zshrc
```

## Usage

### Create a pwnbox
This command will create a container with a given name - `ctf` in this case
```sh
pwnbox create ctf [--image IMAGE_NAME]
# You can optionally pass an image name to override the use of the default image included in this repo
```

### Enter an existing pwnbox
```sh
pwnbox enter ctf 
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

# Change the default image (the one used on pwnbox create)
pwnbox config set --image IMAGE
# Set the default image to the 5GB `pwnbox` image
pwnbox config set --use-slim
# Set the default image to the 15GB image with cross-compilers
pwnbox config set --use-full
```

## Create WSL image from the container
We can extract the root filesystem from the image and use it as a WSL distro! There's a [one line PowerShell command](#automated-install) that will do this for you!

To do it manually, you can head to the [releases page](https://github.com/OBarronCS/pwnbox/releases) to grab the files (the file name ends in `tar.gz`) and go to step 2 below. To build and extract the filesystem locally, start at step 1.

### Step 1 - extract the root filesystem
```powershell
docker create --name wsl-temp pwnbox
# This will take multiple minutes, and it has no progress meter
docker export wsl-temp -o wsl_rootfs.tar
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

### Automated install
Alternatively, you can use this handy one-liner to run a script to do all of these steps for you! It will download the latest `.tar.gz` file from GitHub releases and install it as a distro on WSL. 

```powershell
# The downloaded file will go into PowerShell's current directory
cd $HOME/Downloads
# This is the PowerShell equivalent of "curl | bash"
iwr https://obarroncs.github.io/pwnbox/wsl.ps1 | iex
```

The script is being hosted on `GitHub Pages` and can be found [here](https://github.com/OBarronCS/pwnbox/blob/main/wsl.ps1).


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

