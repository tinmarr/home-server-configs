#!/usr/bin/env bash

dirs=$(eza -D --absolute)

for dir in $dirs; do
    cd $dir
    docker compose pull
    docker compose up -d
done

cd ~/home-server-configs/docker
docker image prune -af
