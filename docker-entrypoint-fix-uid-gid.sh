#!/bin/bash

# Fixes user id and gid to match the ones of launching user on the host
# Inspired by https://denibertovic.com/posts/handling-permissions-with-docker-volumes/

set -o errexit
set -o nounset
set -o pipefail

username=developer

ids_update() {
    groupmod --gid $HOST_GID $username
    usermod --uid $HOST_UID $username
    chown --no-dereference --recursive -P ${username}:${username} /home/${username}
}

current_uid=$(id --user $username)

echo "$username UID is $current_uid, UID of user launching container is $HOST_UID"

if [ "$current_uid" != "$HOST_UID" ] ; then
    echo "Updating UID+GID for $username..."
    ids_update
else
    echo "User UID matches that of the host, looks like we are good to go."
fi

exec /usr/sbin/gosu ${username}:${username} "$@"
