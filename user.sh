#!/bin/bash

# This files contains scripts that install programs regardless of the host operating system
# Arguments (add in no particular order)
# - `server` - whether to install some GUI apps, like Ghidra
# - `noextra` - disable installing some extra dev apps

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
    echo "--------------------"
    echo -e "${GREEN}$1${ENDCOLOR}"
    echo "--------------------"
}

SERVER_MODE="N"
EXTRA="Y"

if [[ "$*" == *"server"* ]]
then
    SERVER_MODE="Y"
fi


if [[ "$*" == *"noextra"* ]]
then
    EXTRA="N"
fi

print_info "Installing fzf"
if [ ! -d "${HOME}/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
else
    print_info "fzf already installed"
fi

INSTALL_PYENV="Y"
if [[ $INSTALL_PYENV =~ ^[Yy] ]]
then
    print_info "Downloading & installing pyenv"
    if [ ! -d "${HOME}/.pyenv" ]; then
        curl https://pyenv.run | bash
        echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc
        echo 'eval "$(pyenv init -)"' >> ~/.bashrc
        
        # Really bad for performance
        # echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc

        # Set environments locally, for this script to work
        export PATH="$HOME/.pyenv/bin:$PATH"
        eval "$(pyenv init -)"
        # eval "$(pyenv virtualenv-init -)"

        print_info "Downloading python 3.11 with pyenv. This may take a moment (it has no progress indicator)"
        pyenv install 3.11 --verbose
        pyenv global 3.11
    else
        print_info "pyenv already installed"
        export PATH="$HOME/.pyenv/bin:$PATH"
        eval "$(pyenv init -)"
    fi
fi


print_info "Installing pwntools"
pip install pwntools

print_info "Installing ROPgadget"
pip install ROPgadget

print_info "Installing z3"
pip install z3-solver

print_info "Installing Keystone"
pip install keystone-engine

print_info "Installing my fork of pwndbg"
if [ ! -d "$HOME/pwndbg" ]; then
	git clone https://github.com/OBarronCS/pwndbg ~/pwndbg
	cd ~/pwndbg
	chmod +x setup.sh
	echo n | ./setup.sh

    if [[ $EXTRA =~ ^[Yy] ]];
    then
        print_info "Installing pwndbg devtools"
        echo y | ./setup-dev.sh
    fi
    
    cd -
else
    print_info "pwndbg is already installed"
fi

print_info "Installing GEP plugin to GDB"
if [ ! -d "$HOME/.local/share/GEP" ]; then
    # You could also choose other directories to install GEP if you want
    git clone --depth 1 https://github.com/lebr0nli/GEP.git ~/.local/share/GEP
    ~/.local/share/GEP/install.sh
fi


# TODO: Make this install globally
print_info "Installing Rust and pwninit (this may take a while)"
if [ ! -d "$HOME/.cargo" ]; then
    # Non-interactive minimal install
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --profile minimal -y
    # rustup component add clippy rustfmt

    source "$HOME/.cargo/env"

    print_info "Installing pwninit"
    cargo install pwninit
else
    print_info "Rust is already installed"
fi


# This install it for everyone
# How did this work for me in the first place? Maybe desktop install permissions are just different?
# Something to do with the gem init? Idk. Seemed to install locally
print_info "Installing seccomp-tools and one_gadget with ruby"
sudo gem install seccomp-tools
sudo gem install one_gadget



print_info "Install node version manager (nvm)"
if [ ! -d "$HOME/.nvm" ]; then
    # Will automatically attempt to update in case it's already installed
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

    # Makes nvm work without restarting shell
    export NVM_DIR="$HOME/.nvm"
    source ~/.nvm/nvm.sh

    print_info "Installing latest version of node"
    nvm install node
else
    print_info "nvm is already installed"
fi


# print_info "Installion bun.js"
# if [ ! -d "$HOME/.bun" ]; then
#     curl -fsSL https://bun.sh/install | bash
# else
#     print_info "Bun is already installed"
# fi


print_info "Installing .dotfiles"
if [ ! -d "${HOME}/.dotfiles" ]; then
    curl https://raw.githubusercontent.com/OBarronCS/.dotfiles/master/install.sh | bash
else
    print_info ".dotfiles already installed, very cool!"
fi

print_info "Adding aliases and .bashrc setup"
if ! grep -Fq 'back(){ $@ & disown ; }' ~/.bashrc; then
    # Unlimited history
    echo "PS1='\[\e[0m\][\[\e[0m\]\u\[\e[0m\]:\[\e[0m\]\w\[\e[0m\]]\[\e[0m\]$ \[\e[0m\]'" >> ~/.bashrc
    echo 'export HISTSIZE=' >> ~/.bashrc
    echo 'export HISTFILESIZE=' >> ~/.bashrc
    echo 'export HISTCONTROL=ignoredups' >> ~/.bashrc
    echo 'alias pwninit="pwninit --no-template"' >> ~/.bashrc
    echo 'back(){ $@ & disown ; }' >> ~/.bashrc
    echo 'codehere(){ back code . ; }' >> ~/.bashrc
    printf 'if [ -f /run/.containerenv  ] || [ -f /run/.toolboxenv ] || [ -f /.dockerenv ];\nthen\n    PS1="🧊 $PS1";\nfi\n' >> ~/.bashrc
    echo "alias gdb=\"gdb -q\"" >> ~/.bashrc
    echo "export EDITOR=vim" >> ~/.bashrc
    echo 'export PATH="$PATH:/$HOME/ctfsetup/bin"' >> ~/.bashrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    # echo 'export PATH="$HOME/.local/share/gem/ruby/3.0.0/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
    echo 'alias ossh="TERM=xterm-256color \\ssh"' >> ~/.bashrc
fi

if ! grep -Fq 'set print object on' ~/.gdbinit; then
    echo "set print object on" >> ~/.gdbinit
    echo "set print vtbl on" >> ~/.gdbinit
    echo "set print symbol-filename on" >> ~/.gdbinit
    echo "set print symbol on" >> ~/.gdbinit
    echo "set print nibbles on" >> ~/.gdbinit

    # Makes all pwndbg errors show a stacktrace
    echo "set exception-verbose on" >> ~/.gdbinit
    echo "set exception-debugger on" >> ~/.gdbinit

    echo "set show-retaddr-reg on" >> ~/.gdbinit
    echo "set show-flags on" >> ~/.gdbinit
    echo "#set nearpc-num-opcode-bytes 4" >> ~/.gdbinit
fi

if ! grep -Fq 'set debuginfod enabled on' ~/.gdbinit; then
    echo "set debuginfod enabled on" >> ~/.gdbinit
fi




# TODO:
# Add some of these aliases and symlinks to dotfiles for the root user

print_info "Installing zoxide"
if ! command -v zoxide &> /dev/null; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
else
    print_info "Zoxide already installed!"
fi


print_info "Done! Make sure to exec into a new shell for changes to take effect"

