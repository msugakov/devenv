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
RUN apt-get install -y apt-transport-https
RUN apt-get update
RUN apt-get install -y code

# Mount point for host projects
RUN mkdir /mnt/projects

# Initialize and jump into developer bootstrap user
ENV bootstrap_user bootstrap-developer
RUN groupadd --gid 9876 ${bootstrap_user}
RUN useradd --create-home --gid 9876 --uid 9876 --shell /usr/bin/zsh ${bootstrap_user}
USER ${bootstrap_user}
ENV homedir /home/${bootstrap_user}

# Basic user setup
RUN git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

# My customizations
RUN mkdir ${homedir}/bootstrap
WORKDIR ${homedir}/bootstrap
RUN git clone https://github.com/msugakov/homedir.git
RUN homedir/install.sh
RUN sed -i 's/ZSH_THEME=.*/ZSH_THEME="ys"/g' ${homedir}/.zshrc

# Leave developer and become root again
USER root

# Prepare for real user
ENV real_user developer
RUN groupadd --gid 4321 ${real_user}
RUN useradd --no-create-home --gid 4321 --uid 4321 --shell /usr/bin/zsh ${real_user}
# enable sudo for real user
RUN echo "${real_user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${real_user}

# Final setup before launch
WORKDIR /home/${real_user}
# Stuff to fix uid and gid of container user
COPY docker-entrypoint-fix-uid-gid.sh /usr/local/bin/docker-entrypoint-fix-uid-gid.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-fix-uid-gid.sh"]
CMD ["/usr/bin/zsh"]
