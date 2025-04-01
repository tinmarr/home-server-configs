#!/usr/bin/env bash

dirs=$(eza -D --absolute)

for dir in $dirs; do
    cd $dir
    docker compose up -d
done
