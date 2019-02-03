#!/bin/bash

# Fixes user id and gid to match the ones of launching user on the host
# Inspired by https://denibertovic.com/posts/handling-permissions-with-docker-volumes/

set -o errexit
set -o nounset
set -o pipefail

bootstrap_user=bootstrap-developer
real_user=developer

first_time_init() {
    groupmod --gid $HOST_GID $real_user
    usermod --uid $HOST_UID $real_user
    rsync --recursive --links --perms --times --one-file-system -og --chown=$real_user:$real_user --progress /home/${bootstrap_user}/ /home/${real_user}
}

if [ -z "$(ls -A /home/$real_user)" ] ; then
    echo "Looks like this is the first time this container is started. Initializing user $real_user..."
    first_time_init
else
    echo "Home directory of $real_user is not empty, proceeding without modifications."
fi

#find /home/${real_user} -ls

exec /usr/sbin/gosu ${real_user}:${real_user} "$@"
