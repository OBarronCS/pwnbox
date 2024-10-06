#!/bin/bash

# Generic install script to setup an Ubuntu VM/WSL

# Usage:
# ./init.sh [vmtools]
# Include the optional parameter to install the tools specified

# If it fails at any point, can rerun the script safely

# Exit when any command fails
set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command failed with exit code $?."' EXIT


RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

function print_info {
    echo "----------"
    echo -e "${GREEN}$1${ENDCOLOR}"
    echo "----------"
}


# VM specific
INSTALL_OPEN_VM_TOOLS="N"

if [[ "$*" == *"vmtools"* ]]
then
    INSTALL_OPEN_VM_TOOLS="Y"
fi

# sudo flushes environment variables, use -E flag to preserve it
export DEBIAN_FRONTEND=noninteractive
sudo dpkg --add-architecture i386
sudo apt update -y && sudo apt upgrade -y


if [[ $INSTALL_OPEN_VM_TOOLS =~ ^[Yy] ]]
then
    print_info "Installing open-vm-tools"
    sudo apt install -y open-vm-tools
    sudo apt install -y open-vm-tools-desktop
fi


print_info "Installing core tools"
sudo apt install -y curl wget
sudo apt install -y zip unzip
sudo apt install -y tmux
sudo apt install -y ltrace strace
sudo apt install -y jq

print_info "Installing vim"
sudo apt install -y vim

print_info "Installing git"
sudo apt install -y git

print_info "gdb"
sudo apt install -y gdb gdbserver gdb-multiarch

print_info "Installing debuginfod"
sudo apt install -y debuginfod

echo 'export DEBUGINFOD_URLS="https://debuginfod.ubuntu.com"' >> ~/.bashrc
echo "set debuginfod enabled on" >> ~/.bashrc

print_info "Installing kitty-terminfo"
sudo apt install -y kitty-terminfo

print_info "nmap"
sudo apt install -y nmap

print_info "Installing packages for 32bit development"
sudo apt install -y gcc-multilib g++-multilib
# Debugging symbols
sudo apt install -y debuginfod
sudo apt install -y libc6-dbg libc6-dbg:i386
sudo apt install -y libstdc++6:i386

print_info "Installing command-not-found"
sudo apt install -y command-not-found
# Fill command-not-found database
sudo apt update -y

print_info "Installing ruby-dev"
sudo apt install -y ruby-dev

# Ghidra requires java
print_info "Install java21 for Ghidra"
sudo apt install -y openjdk-21-jdk

print_info "Installing pwninit dependencies"
sudo apt install -y libssl-dev liblzma-dev pkg-config patchelf

## pyenv build tools
print_info "Installing python build tools"
sudo apt install -y build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev


print_info "Installing docker"
print_info "Installing Docker's official GPG key"

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER

print_info "Installing golang"
sudo apt install -y golang-go
