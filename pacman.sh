#!/bin/sh

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


print_info "Installing git"
sudo pacman -S --needed --noconfirm git
sudo pacman -S --needed --noconfirm github-cli

print_info "Installing wget and curl"
sudo pacman -S --needed --noconfirm wget
sudo pacman -S --needed --noconfirm curl
sudo pacman -S --needed --noconfirm netcat-traditional

print_info "Installing tmux"
sudo pacman -S --needed --noconfirm tmux

print_info "Installing many tools (ltrace strace ruby jq zip unzip)"
sudo pacman -S --needed --noconfirm ltrace strace
sudo pacman -S --needed --noconfirm ruby
sudo pacman -S --needed --noconfirm jq
sudo pacman -S --needed --noconfirm zip unzip
sudo pacman -S --needed --noconfirm patchelf

print_info "Installing man pages"
sudo pacman -S --needed --noconfirm man-db
sudo pacman -S --needed --noconfirm man-pages

print_info "Installing python build tools for pyenv"
sudo pacman -S --needed --noconfirm base-devel openssl zlib xz tk

print_info "Installing Docker"
sudo pacman -S --needed --noconfirm docker
sudo pacman -S --needed --noconfirm docker-compose
sudo pacman -S --needed --noconfirm docker-buildx 
# Add user to the docker group
sudo usermod -aG docker $USER


print_info "Installing pahole"
sudo pacman -S --needed --noconfirm pahole

print_info "Installing go"
sudo pacman -S --needed --noconfirm go

print_info "Installing Java for Ghidra"
sudo pacman -S --needed --noconfirm jdk21-openjdk

print_info "Installing reflector"
sudo pacman -S --needed --noconfirm reflector

print_info "Installing distrobox"
wget -qO- https://raw.githubusercontent.com/89luca89/distrobox/main/install | sudo sh

print_info "Installing kitty"
sudo pacman -S --needed --noconfirm kitty

print_info "Installing yay"
if ! command -v yay >/dev/null 2>&1
then
    git clone https://aur.archlinux.org/yay-bin.git ~/yay-bin
    cd ~/yay-bin
    makepkg -si
    cd -
else
    print_info "yay already installed"
fi

print_info "Installing 32-bit glibc"
sudo pacman -S --needed --noconfirm lib32-glibc

print_info "Installing bash-completion"
sudo pacman -S --needed --noconfirm bash-completion

print_info "Installing support for emoji's"
sudo pacman -S --needed --noconfirm noto-fonts-emoji

print_info "Installing spectacle (screenshot tool)"
sudo pacman -S --needed --noconfirm spectacle

print_info "Installing wl-clipboard"
sudo pacman -S --needed --noconfirm wl-clipboard

print_info "Installing greeter screen"
sudo pacman -S --needed --noconfirm sddm-kcm


print_info "Installing remmina"
sudo pacman -S --needed --noconfirm remmina
sudo pacman -S --needed --noconfirm freerdp

print_info "Installing tools for dig (bind)"
sudo pacman -S --needed --noconfirm bind

print_info "Installing vlc"
sudo pacman -S --needed --noconfirm vlc

print_info "Installing Wireshark"
sudo pacman -S --needed --noconfirm wireshark-qt

print_info "Installing Chrome"
yay -S --needed --noconfirm google-chrome

print_info "Installing vscode"
yay -S --needed --noconfirm visual-studio-code-bin

