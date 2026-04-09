#!/bin/bash

# This files contains scripts that install programs regardless of the host operating system
# Arguments (add in no particular order)
# - `server` - whether to install some GUI apps
# - `extra` - enable installing some extra dev apps
# - `lite` - just install the essentials

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
EXTRA="N"
LITE_MODE="N"

if [[ "$*" == *"server"* ]]
then
    SERVER_MODE="Y"
fi

if [[ "$*" == *"extra"* ]]
then
    EXTRA="Y"
fi

if [[ "$*" == *"lite"* ]]
then
    LITE_MODE="Y"
fi


INSTALL_MISE="N"
INSTALL_RUBY_TOOLS="N"

INSTALL_UV="Y"
INSTALL_PYENV="Y"
INSTALL_NVM="Y"
INSTALL_PWNDBG="Y"
INSTALL_RUST="Y"
INSTALL_ZOXIDE="Y"

INSTALL_PWNINIT="Y"

if [[ $LITE_MODE =~ ^[Yy] ]]
then
    INSTALL_PYENV="N"
    INSTALL_NVM="N"
    INSTALL_PWNDBG="N"
    INSTALL_PWNINIT="N"
fi


print_info "Installing fzf"
if [ ! -d "${HOME}/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
else
    print_info "fzf already installed"
fi


if [[ $INSTALL_MISE =~ ^[Yy] ]]
then
    print_info "Installing mise"
    if ! command -v uv &> /dev/null; then
        print_info "Installing mise"
        curl https://mise.run | sh
        echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
    else
        print "Mise already installed"
    fi
fi

# This is where uv is loaded
export PATH="$HOME/.local/bin:$PATH"

if [[ $INSTALL_UV =~ ^[Yy] ]]
then
    print_info "Installing uv"
    if ! command -v uv &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
        # uv python install 3.13 --default
    else
        print_info "uv already installed!"
    fi
fi

if [[ $INSTALL_PYENV =~ ^[Yy] ]]
then
    print_info "Downloading & installing pyenv"
    if [ ! -d "${HOME}/.pyenv" ]; then
        curl -fsSL https://pyenv.run | bash
        echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc
        echo 'eval "$(pyenv init -)"' >> ~/.bashrc
        
        # Really bad for performance
        # echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc

        # Set environments locally, for this script to work
        export PATH="$HOME/.pyenv/bin:$PATH"
        eval "$(pyenv init -)"
        # eval "$(pyenv virtualenv-init -)"

        print_info "Downloading python 3.13 with pyenv. This may take a moment"
        pyenv install 3.13 --verbose
        pyenv global 3.13

        # TODO: should these be installed?
        print_info "Installing pwntools"
        pip install pwntools

        print_info "Installing ROPgadget"
        pip install ROPgadget

        print_info "Installing z3"
        pip install z3-solver
    else
        print_info "pyenv already installed"
        export PATH="$HOME/.pyenv/bin:$PATH"
        eval "$(pyenv init -)"
    fi
fi

if [[ $INSTALL_NVM =~ ^[Yy] ]]
then
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
fi


if [[ $INSTALL_PWNDBG =~ ^[Yy] ]]
then
    print_info "Installing my fork of pwndbg"
    if [ ! -d "$HOME/pwndbg" ]; then
        git clone --depth 1 https://github.com/OBarronCS/pwndbg ~/pwndbg
        pushd ~/pwndbg

        # Classic setup
        if [[ $EXTRA =~ ^[Yy] ]];
        then
            chmod +x setup.sh
            echo n | ./setup.sh
            print_info "Installing pwndbg devtools"
            echo y | ./setup-dev.sh
        else
            PY_VER=$(gdb -nx --batch -iex 'py import sysconfig; print(sysconfig.get_config_var("VERSION"))')
            uv tool install --python=$PY_VER .
            echo "source $(uv tool dir)/pwndbg/share/pwndbg/gdbinit.py" >> ~/.gdbinit
        fi

        popd
    else
        print_info "pwndbg is already installed"
    fi

    print_info "Installing GEP plugin to GDB"
    if [ ! -d "$HOME/.local/share/GEP" ]; then
        # You could also choose other directories to install GEP if you want
        git clone --depth 1 https://github.com/lebr0nli/GEP.git ~/.local/share/GEP
        ~/.local/share/GEP/install.sh --uv
    fi
fi

if [[ $INSTALL_RUST =~ ^[Yy] ]]
then
    print_info "Installing Rust"
    if [ ! -d "$HOME/.cargo" ]; then
        # Non-interactive minimal install
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --profile minimal -y
        # rustup component add clippy rustfmt

        source "$HOME/.cargo/env"

        if [[ $INSTALL_PWNINIT =~ ^[Yy] ]]
        then
            print_info "Installing pwninit (this may take a while)"
            cargo install pwninit
        fi

        print_info "Installing seabox"
        cargo install --git https://github.com/OBarronCS/seabox.git
    else
        print_info "Rust is already installed"
    fi
fi

if [[ $INSTALL_RUBY_TOOLS =~ ^[Yy] ]]
then
	cat <<-'EOF' >> ~/.bashrc
	if command -v ruby >/dev/null 2>&1; then
		PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"
	fi
	EOF

    print_info "Installing seccomp-tools and one_gadget with ruby"
    gem install seccomp-tools
    gem install one_gadget
fi




print_info "Installing .dotfiles"
if [ ! -d "${HOME}/.dotfiles" ]; then
    git clone https://github.com/OBarronCS/.dotfiles.git ~/.dotfiles
    ~/.dotfiles/setup.sh
else
    print_info ".dotfiles already installed, very cool!"
fi

if [[ $INSTALL_ZOXIDE =~ ^[Yy] ]]
then
    print_info "Installing zoxide"
    if ! command -v zoxide &> /dev/null; then
        # curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        # The curl install method hits rate limit on GitHub API
        cargo install zoxide --locked
    else
        print_info "Zoxide already installed!"
    fi
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
    echo 'export PATH="$PATH:$HOME/ctfsetup/bin"' >> ~/.bashrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
    echo 'alias ossh="TERM=xterm-256color \\ssh"' >> ~/.bashrc
    echo 'alias tmo="history -a; tmux"' >> ~/.bashrc
    echo 'alias ipi="PWNLIB_NOTERM=1 PYTHONSTARTUP=~/.pythonrc.py python"' >> ~/.bashrc

    echo 'export FZF_CTRL_R_OPTS='\''--bind "enter:become:if [[ -n {} ]]; then echo {}; else echo {q}; fi" --bind "ctrl-c:become:echo {q}"'\''' >> ~/.bashrc

fi

if [ ! -f ~/.gdbinit ] || ! grep -Fq 'set print object on' ~/.gdbinit; then
    # Pwndbg settings
    echo "set exception-verbose on" >> ~/.gdbinit
    echo "set exception-debugger on" >> ~/.gdbinit

    echo "set show-flags on" >> ~/.gdbinit
    echo "set show-retaddr-reg on" >> ~/.gdbinit
    echo "#set nearpc-num-opcode-bytes 4" >> ~/.gdbinit

    echo "set print object on" >> ~/.gdbinit
    echo "set print vtbl on" >> ~/.gdbinit
    echo "set print symbol-filename on" >> ~/.gdbinit
    echo "set print symbol on" >> ~/.gdbinit
    echo "set print nibbles on" >> ~/.gdbinit
    echo "set print asm-demangle on" >> ~/.gdbinit
    echo "set output-radix 16" >> ~/.gdbinit
fi

if ! grep -Fq 'set debuginfod enabled on' ~/.gdbinit; then
    echo "set debuginfod enabled on" >> ~/.gdbinit
fi

# TODO:
# Add some of these aliases and symlinks to dotfiles for the root user


print_info "Done! Make sure to exec into a new shell for changes to take effect"

