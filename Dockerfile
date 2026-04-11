ARG UBUNTU_VERSION=25.04
FROM ubuntu:${UBUNTU_VERSION} AS base

RUN apt-get update -y && apt-get install -y unminimize
RUN yes | unminimize

RUN dpkg --add-architecture i386
RUN apt-get update -y \
    && apt-get install -y \
    linux-base \
    curl wget socat netcat-openbsd \
    manpages-posix-dev \
    man-db \
    git \
    zip unzip \
    tmux \
    locales tzdata \
    gdb gdbserver gdb-multiarch debuginfod \
    strace ltrace procps \
    pahole \
    sudo \
    vim less rlwrap \
    kitty-terminfo \
    lsb-release \
    file \
    jq \
    p7zip-full \
    nmap tcpdump telnet \
    capstone-tool \
    ruby-dev perl \
    bat \
    iproute2 iptables traceroute dnsutils lsof net-tools \
    apt-transport-https apt-utils iputils-ping software-properties-common \
    steghide stegcracker john \
    libc6-dbg libc6-dbg:i386 libstdc++6:i386 \
    libssl-dev liblzma-dev pkg-config patchelf \
    build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
    autoconf automake libtool flex bison \
    cmake \
    podman \
    dbus cron dirmngr dmidecode gnupg kmod udev \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update -y && \
    apt-get install -y systemd && \
    find /etc/systemd/system \
	/lib/systemd/system \
	-path '*.wants/*' \
	\( -name '*getty*' \
	-or -name '*apt-daily*' \
	-or -name '*systemd-timesyncd*' \
	-or -name '*systemd-logind*' \
	-or -name '*systemd-vconsole-setup*' \
	-or -name '*systemd-readahead*' \
	-or -name '*udev*' \) \
	-exec rm -v {} \; && \
	systemctl set-default multi-user.target && \
	systemctl mask dev-hugepages.mount sys-fs-fuse-connections.mount network.service

# Install PowerShell - broken for 25.04 currently
# # https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu
# RUN . /etc/os-release \
#     && wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb \
#     && dpkg -i packages-microsoft-prod.deb \
#     && rm packages-microsoft-prod.deb \
#     && apt-get update \
#     && apt-get install -y powershell \
#     && rm -rf /var/lib/apt/lists/*

ARG FULL_BUILD=false

# Install cross compilers
RUN if [ "$FULL_BUILD" = "true" ]; then \
    apt-get update -y && apt-get install -y \
    llvm \
    qemu-system qemu-kvm qemu-user qemu-user-binfmt \
    gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
        libc6-arm64-cross libc6-dbg-arm64-cross libstdc++6-11-dbg-arm64-cross libstdc++-11-pic-arm64-cross \
    gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
        libc6-armel-cross libc6-armhf-cross libc6-dbg-armhf-cross libstdc++6-11-dbg-armhf-cross libstdc++-11-pic-armhf-cross \
    gcc-mips-linux-gnu g++-mips-linux-gnu \
        libc6-mips-cross \
    gcc-mips64-linux-gnuabi64 g++-mips64-linux-gnuabi64 \
        libc6-mips64-cross \
    gcc-riscv64-linux-gnu g++-riscv64-linux-gnu \
        libc6-riscv64-cross \
    gcc-powerpc-linux-gnu g++-powerpc-linux-gnu \
        libc6-powerpc-cross libc6-ppc64-cross \
    gcc-sparc64-linux-gnu g++-sparc64-linux-gnu \
        libc6-sparc64-cross \
    gcc-loongarch64-linux-gnu \
        libc6-loong64-cross \
    && rm -rf /var/lib/apt/lists/* ; \
    fi

RUN mkdir /etc/qemu-binfmt && \
    mkdir /usr/gnemul && \
    ln -s /usr/aarch64-linux-gnu /etc/qemu-binfmt/aarch64 && \
        ln -s /etc/qemu-binfmt/aarch64 /usr/gnemul/qemu-aarch64 && \
    ln -s /usr/arm-linux-gnueabihf /etc/qemu-binfmt/arm && \
        ln -s /etc/qemu-binfmt/arm /usr/gnemul/qemu-arm && \
    ln -s /usr/mips-linux-gnu /etc/qemu-binfmt/mips && \
        ln -s /etc/qemu-binfmt/mips /usr/gnemul/qemu-mips && \
    ln -s /usr/mips64-linux-gnuabi64/ /etc/qemu-binfmt/mips64 && \
        ln -s /etc/qemu-binfmt/mips64  /usr/gnemul/qemu-mips64 && \
    ln -s /usr/powerpc-linux-gnu/ /etc/qemu-binfmt/ppc && \
        ln -s /etc/qemu-binfmt/ppc  /usr/gnemul/qemu-ppc && \
    ln -s /usr/powerpc64-linux-gnu/ /etc/qemu-binfmt/ppc64 && \
        ln -s /etc/qemu-binfmt/ppc64  /usr/gnemul/qemu-ppc64 && \
    ln -s /usr/sparc64-linux-gnu/ /etc/qemu-binfmt/sparc64 && \
        ln -s /etc/qemu-binfmt/sparc64 /usr/gnemul/qemu-sparc64 && \
    ln -s /usr/riscv64-linux-gnu/ /etc/qemu-binfmt/riscv64 && \
        ln -s /etc/qemu-binfmt/riscv64 /usr/gnemul/qemu-riscv64 && \
    ln -s /usr/loongarch64-linux-gnu/ /usr/gnemul/qemu-loongarch64

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV LANGUAGE=en_US:en

# ARG USER=pwn
# RUN useradd --groups sudo --no-create-home --shell /bin/bash ${USER} \
    # && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
    # && chmod 0440 /etc/sudoers.d/${USER}
# USER ${USER}
# WORKDIR /home/${USER}
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu

USER ubuntu
WORKDIR /home/ubuntu

RUN echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc && \
    echo "export LANG=en_US.UTF-8" >> ~/.bashrc && \
    echo "export LANGUAGE=en_US.UTF-8" >> ~/.bashrc && \
    echo 'export DEBUGINFOD_URLS="https://debuginfod.ubuntu.com"' >> ~/.bashrc && \
    echo "set debuginfod enabled on" >> ~/.bashrc && \
    echo '[[ -f ~/.bashrc ]] && . ~/.bashrc' > ~/.bash_profile

COPY --chown=ubuntu user.sh ./.user.sh

RUN if [ "$FULL_BUILD" = "true" ]; then \
        ./.user.sh server extra; \
    else \
        ./.user.sh server; \
    fi

LABEL description="An environment for CTF and reverse-engineering!"
LABEL SEABOX_USER_ID=1000

# In the WSL build, include ghidra
FROM base AS wsl
COPY --chown=ubuntu install_ghidra.sh ./.install_ghidra.sh
# TODO: also install openjdk-21-jdk if running this
# RUN ./.install_ghidra.sh

COPY --chown=ubuntu wsl.sh ./.wsl.sh
RUN sudo ./.wsl.sh

LABEL description="An environment for CTF and reverse-engineering!"
LABEL SEABOX_USER_ID=1000
