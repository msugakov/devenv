FROM ubuntu:18.10

# Basic stuff
ENV installer apt-get install -y --no-install-recommends
RUN apt-get update

# The thing which allows to use apt packages cache and not download same stuff from internet all the time
# See https://gist.github.com/dergachev/8441335
# See https://github.com/pmoust/squid-deb-proxy
# Build that one with `sudo docker build -t apt-proxy .`
# Run with `sudo docker run --name apt-proxy --rm --mount type=bind,source=/home/mixa/apt-docker-cache,target=/cachedir --publish 38000:8000 apt-proxy`
RUN ${installer} net-tools netcat-openbsd
COPY detect-apt-proxy.sh /root
RUN /root/detect-apt-proxy.sh 38000

# Base system
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y dist-upgrade
RUN ${installer} curl ca-certificates
RUN ${installer} apt-utils aptitude zsh gnupg rsync sudo openssh-client

# some ui stuff TODO: re-enable firefox
#RUN ${installer} firefox

# dev stuff
RUN ${installer} git
RUN ${installer} gcc g++ cmake make
# To drop priveleges from ENTRYPOINT script
RUN ${installer} gosu

# install node
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN ${installer} nodejs

# Install VS Code - https://code.visualstudio.com/docs/setup/linux
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
RUN install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
RUN sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
RUN ${installer} apt-transport-https libasound2
RUN apt-get update
#RUN ${installer} code

# Install Yarn - https://yarnpkg.com/en/docs/install#debian-stable
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update
RUN ${installer} yarn

# Install packages for development
RUN yarn global add bs-platform
RUN yarn global add vuepress

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
