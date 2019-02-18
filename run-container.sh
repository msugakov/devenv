#!/bin/bash

# Starts docker container in the right way by specifying uid and gid of the host OS

set -o errexit
set -o nounset
set -o pipefail

host_uid=$1
shift
host_gid=$1
shift

echo "Assuming host_uid=${host_uid} host_gid=${host_gid}"

# X11 connection inspired by https://github.com/cmiles74/docker-vscode

exec docker run \
    --hostname devenv \
    --interactive \
    --tty \
    --env HOST_UID=$host_uid \
    --env HOST_GID=$host_gid \
    --publish 8080:8080 \
    --mount type=volume,source=devenv-home-overlay,target=/home \
    --mount type=bind,source=$HOME/projects,target=/mnt/projects \
    --mount type=bind,source=/tmp/.X11-unix,target=/tmp/.X11-unix \
    --env DISPLAY=unix${DISPLAY} \
    --device /dev/snd \
    node-dev "$@"
