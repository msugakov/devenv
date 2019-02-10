#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

APT_PROXY_PORT=$1
HOST_IP=$(route -n | awk '/^0.0.0.0/ {print $2}')
nc -z "$HOST_IP" ${APT_PROXY_PORT}

if [ $? -eq 0 ]; then
    cat >> /etc/apt/apt.conf.d/30proxy <<EOL
    Acquire::http::Proxy "http://$HOST_IP:$APT_PROXY_PORT";
    Acquire::http::Proxy::ppa.launchpad.net DIRECT;
    Acquire::http::Proxy::deb.nodesource.com DIRECT;
    Acquire::http::Proxy::packages.microsoft.com DIRECT;
    Acquire::http::Proxy::dl.yarnpkg.com DIRECT;
EOL
    cat /etc/apt/apt.conf.d/30proxy
    echo "Using host's apt proxy"
else
    >&2 echo "No apt proxy detected on Docker host"
fi
