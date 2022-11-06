#!/bin/bash

set -o allexport
source /tmp/.env
set +o allexport

docker run --detach \
    --network intranet \
    --name tunnel \
    --hostname tunnel-$HOSTNAME \
    --restart always \
    cloudflare/cloudflared:latest \
    tunnel --no-autoupdate run --token $cloudflared_token