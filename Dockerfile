FROM ubuntu:18.04

# basic stuff
RUN apt-get update
RUN apt-get install -y apt-utils aptitude zsh curl gnupg rsync sudo

# some ui stuff TODO: re-enable firefox
#RUN apt-get install -y firefox

# dev stuff
RUN apt-get install -y git

# To drop priveleges from ENTRYPOINT script
RUN apt-get install -y gosu

# install node
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs

# install VS Code - https://code.visualstudio.com/docs/setup/linux
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
RUN install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
RUN sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
RUN apt-get install -y apt-transport-https libasound2
RUN apt-get update
RUN apt-get install -y code

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
