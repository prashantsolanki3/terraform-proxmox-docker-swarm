#!/bin/bash

set -o allexport
source /tmp/.env
set +o allexport

docker network create -d overlay --attachable intranet
docker network create -d overlay --attachable db

docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token $cloudflared_token

# docker service create --replicas 3 \
#     --name tunnel \
#     --hostname tunnel \
#     --network intranet \
#     cloudflare/cloudflared:latest \
#         --no-autoupdate run \
#         --token $cloudflared_token
cd /tmp
docker stack deploy --compose-file <(docker-compose config) essentials