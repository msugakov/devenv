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

exec docker run --interactive --tty --env HOST_UID=$host_uid --env HOST_GID=$host_gid --mount type=bind,source=$HOME/projects,target=/mnt/projects node-dev "$@"
