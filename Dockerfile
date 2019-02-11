# syntax = docker/dockerfile:experimental
FROM ubuntu:18.10

# Set for caching apt packages
# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/experimental.md
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Basic stuff
ENV installer apt-get install -y --no-install-recommends
RUN --mount=type=cache,target=/var/cache/apt apt-get update

# Base system
RUN --mount=type=cache,target=/var/cache/apt apt-get update
RUN --mount=type=cache,target=/var/cache/apt apt-get -y upgrade
RUN --mount=type=cache,target=/var/cache/apt apt-get -y dist-upgrade
RUN --mount=type=cache,target=/var/cache/apt ${installer} curl ca-certificates
RUN --mount=type=cache,target=/var/cache/apt ${installer} apt-utils aptitude zsh gnupg rsync sudo openssh-client less

# some ui stuff TODO: re-enable firefox
#RUN --mount=type=cache,target=/var/cache/apt ${installer} firefox

# dev stuff
RUN --mount=type=cache,target=/var/cache/apt ${installer} git
RUN --mount=type=cache,target=/var/cache/apt ${installer} gcc g++ cmake make
# To drop priveleges from ENTRYPOINT script
RUN --mount=type=cache,target=/var/cache/apt ${installer} gosu

# install node
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN --mount=type=cache,target=/var/cache/apt ${installer} nodejs

# Install VS Code - https://code.visualstudio.com/docs/setup/linux
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
RUN install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
RUN sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
RUN --mount=type=cache,target=/var/cache/apt ${installer} apt-transport-https libasound2
RUN --mount=type=cache,target=/var/cache/apt apt-get update
# TODO: reenable VS Code if need arises
#RUN --mount=type=cache,target=/var/cache/apt ${installer} code

# Install Yarn - https://yarnpkg.com/en/docs/install#debian-stable
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
RUN --mount=type=cache,target=/var/cache/apt apt-get update
RUN --mount=type=cache,target=/var/cache/apt ${installer} yarn

# Install yarn/npm packages for development
RUN mkdir -p /root/yarn-cache
RUN --mount=type=cache,target=/root/yarn-cache yarn global --cache-folder /root/yarn-cache add bs-platform
RUN --mount=type=cache,target=/root/yarn-cache yarn global --cache-folder /root/yarn-cache add vuepress
RUN --mount=type=cache,target=/root/yarn-cache yarn global --cache-folder /root/yarn-cache add nativescript

# Mount point for host projects
RUN mkdir /mnt/projects

# Initialize and jump into developer bootstrap user
ENV username developer
RUN groupadd --gid 9876 ${username}
RUN useradd --create-home --gid 9876 --uid 9876 --shell /usr/bin/zsh ${username}
USER ${username}
ENV homedir /home/${username}

# Basic user setup
RUN git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

# My customizations
RUN mkdir ${homedir}/bootstrap
WORKDIR ${homedir}/bootstrap
RUN git clone https://github.com/msugakov/homedir.git
RUN homedir/install.sh
RUN sed -i 's/ZSH_THEME=.*/ZSH_THEME="ys"/g' ${homedir}/.zshrc
RUN ln -v --symbolic /mnt/projects ${homedir}/projects

# Leave developer and become root again
USER root

# enable sudo for real user
RUN echo "${username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${username}

# Final setup before launch
WORKDIR ${homedir}
# Stuff to fix uid and gid of container user
COPY docker-entrypoint-fix-uid-gid.sh /usr/local/bin/docker-entrypoint-fix-uid-gid.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-fix-uid-gid.sh"]
CMD ["/usr/bin/zsh"]
