#!/bin/bash

echo "--------------------------------------------"
echo "Start nginx proxy"
echo "--------------------------------------------"

SCRIPT_PATH="$(dirname "$0")"

docker service rm proxy || true
sleep 10

if ! docker service create \
  --name proxy \
  --replicas 3 \
  --network cms \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,readonly=true,source="$SCRIPT_PATH"/nginx.conf,target=/etc/nginx/nginx.conf \
  nginx:stable; then
  echo "proxy service error"
  exit 1;
fi
