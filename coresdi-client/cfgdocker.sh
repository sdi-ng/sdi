#!/bin/bash

PREFIX=$(dirname $0)

if [ ! -e $PREFIX'/config' ]; then
    echo "ERROR: The $PREFIX/config  file does not exist or can not be accessed"
    exit 1
fi

source $PREFIX'/config'

printf '{ "insecure-registries": ["'$DOCKER_REGISTRY_IP'"] }' > /etc/docker/daemon.json

systemctl restart docker