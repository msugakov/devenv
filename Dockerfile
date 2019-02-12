# syntax = docker/dockerfile:experimental
FROM ubuntu:18.10

# Set for caching apt packages
# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/experimental.md
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Basic stuff
ENV installer apt-get install -y --no-install-recommends

# Base system, developer stuff and stuff for GUI apps.
# openjdk-8-jdk is required by Android SDK which does not work on Java 11.
RUN --mount=type=cache,target=/var/cache/apt apt-get update \
&& DEBIAN_FRONTEND=noninteractive ${installer} \
    apt-transport-https \
    apt-utils \
    aptitude \
    ca-certificates \
    cmake \
    curl \
    g++ \
    gcc \
    git \
    gnupg \
    gosu \
    less \
    lib32ncurses6 \
    lib32z1 \
    libasound2 \
    libx11-xcb1 \
    libxtst6 \
    make \
    nano \
    openjdk-8-jdk \
    openssh-client \
    rsync \
    sudo \
    unzip \
    zsh

#    firefox
#     xorg \
#     android-sdk \

# Get node repo
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

# Get VS Code repo - https://code.visualstudio.com/docs/setup/linux
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

# Get Yarn repo - https://yarnpkg.com/en/docs/install#debian-stable
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Install node, code and yarn
RUN --mount=type=cache,target=/var/cache/apt apt-get update && ${installer} \
    nodejs \
    code \
    yarn

# Install yarn/npm packages for development
RUN mkdir -p /root/yarn-cache
RUN --mount=type=cache,target=/root/yarn-cache yarn global --cache-folder /root/yarn-cache add \
    bs-platform \
    vuepress \
    nativescript

# Install Android SDK
# File was be downloaded from https://developer.android.com/studio/#Other
# and then updated with sdkmanager with packages listed in
# https://docs.nativescript.org/angular/start/ns-setup-linux
# Ideally, this should be scripted to be done in docker but don't feel too enthusiastic about it at the moment.
COPY android-sdk.tgz /root/
RUN tar -xpf /root/android-sdk.tgz --directory /opt

# TODO: set android SDK paths

# Mount point for host projects
RUN mkdir /mnt/projects

# Initialize and jump into developer user. Enable sudo for user.
ENV username developer
RUN groupadd --gid 9876 ${username} && \
    useradd --create-home --gid 9876 --uid 9876 --shell /usr/bin/zsh ${username} && \
    echo "${username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${username}
USER ${username}
ENV homedir /home/${username}

# Basic user setup
RUN git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

# My customizations
RUN mkdir ${homedir}/bootstrap
WORKDIR ${homedir}/bootstrap
RUN git clone https://github.com/msugakov/homedir.git && \
    homedir/install.sh && \
    sed -i 's/ZSH_THEME=.*/ZSH_THEME="ys"/g' ${homedir}/.zshrc && \
    ln -v --symbolic /mnt/projects ${homedir}/projects

# Leave developer and become root again
USER root

# Final setup before launch
WORKDIR ${homedir}
# Stuff to fix uid and gid of container user
COPY docker-entrypoint-fix-uid-gid.sh /usr/local/bin/docker-entrypoint-fix-uid-gid.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-fix-uid-gid.sh"]
CMD ["/usr/bin/zsh"]
