#!/bin/bash

# Detects and configures APT proxy which should run on host or in another container.
# See Dockerfile for more info.

set -o errexit
set -o nounset
set -o pipefail

APT_PROXY_PORT=$1
HOST_IP=$(route -n | awk '/^0.0.0.0/ {print $2}')

if nc -z "$HOST_IP" ${APT_PROXY_PORT}; then
    # TODO: add more exclusions below if you see errors during packages fetching or apt-get update.
    # Acquire::http::Proxy::ppa.launchpad.net DIRECT;
    # Acquire::http::Proxy::deb.nodesource.com DIRECT;
    # Acquire::http::Proxy::packages.microsoft.com DIRECT;
    # Acquire::http::Proxy::dl.yarnpkg.com DIRECT;
    # Acquire::https::proxy "https://$HOST_IP:$APT_PROXY_PORT";
    cat >> /etc/apt/apt.conf.d/30proxy <<EOL
    Acquire::http::Proxy "http://$HOST_IP:$APT_PROXY_PORT";
    Acquire::ftp::proxy "ftp://$HOST_IP:$APT_PROXY_PORT";
EOL
    cat /etc/apt/apt.conf.d/30proxy
    echo "Using host's apt proxy"
else
    >&2 echo "No apt proxy detected on Docker host"
fi
