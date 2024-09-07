# FROM ubuntu:24.04
FROM dokken/ubuntu-24.04 AS base

RUN dpkg --add-architecture i386
RUN apt-get update -y \
    && apt-get install -y \
    curl wget socat netcat-openbsd \
    git \
    zip unzip \
    tmux \
    locales \
    gdb gdbserver gdb-multiarch debuginfod \
    strace ltrace \
    pahole \
    sudo \
    vim \
    kitty-terminfo \
    file \
    jq \
    p7zip-full \
    nmap \
    capstone-tool \
    ruby-dev \
    openjdk-17-jdk \
    bat \
    iproute2 traceroute \
    libc6-dbg libc6-dbg:i386 libstdc++6:i386 \
    libssl-dev liblzma-dev pkg-config patchelf \
    build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
    qemu-system qemu-kvm qemu-user qemu-user-binfmt \
    autoconf automake libtool flex bison \
    && rm -rf /var/lib/apt/lists/*

ARG FULL_BUILD=false

# Install cross compilers
RUN if [ "$FULL_BUILD" = "true" ]; then \
    apt-get install -y llvm && \
    gcc-14-aarch64-linux-gnu g++-14-aarch64-linux-gnu \
        libc6-arm64-cross libc6-dbg-arm64-cross libstdc++6-11-dbg-arm64-cross libstdc++-11-pic-arm64-cross \
    gcc-14-arm-linux-gnueabihf g++-14-arm-linux-gnueabihf \
        libc6-armel-cross libc6-armhf-cross libc6-dbg-armhf-cross libstdc++6-11-dbg-armhf-cross libstdc++-11-pic-armhf-cross \
    gcc-13-mips-linux-gnu g++-13-mips-linux-gnu \
        libc6-mips-cross \
    gcc-13-mips64-linux-gnuabi64 g++-13-mips64-linux-gnuabi64 \
        libc6-mips64-cross \
    gcc-14-riscv64-linux-gnu g++-14-riscv64-linux-gnu \
        libc6-riscv64-cross \
    gcc-14-powerpc-linux-gnu g++-14-powerpc-linux-gnu \
        libc6-powerpc-cross libc6-ppc64-cross \
    gcc-14-sparc64-linux-gnu g++-14-sparc64-linux-gnu \
        libc6-sparc64-cross \
    && rm -rf /var/lib/apt/lists/* ; \
    fi


RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV LANGUAGE=en_US:en

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
        ln -s /etc/qemu-binfmt/riscv64 /usr/gnemul/qemu-riscv64

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

COPY --chown=ubuntu user.sh .
RUN if [ "$FULL_BUILD" = "true" ]; then \
        ./user.sh server; \
    else \
        ./user.sh server noextra; \
    fi

COPY --chown=ubuntu wsl.sh .

RUN sudo wsl.sh
