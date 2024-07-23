#!/bin/bash

echo "$TOKEN" | docker login ghcr.io -u "$USERNAME" --password-stdin
SCRIPT_PATH="$(dirname "$0")"

Cleanup () {
  docker logout ghcr.io
  docker volume prune --all --force || true
  docker system prune --force --all --volumes || true
}

echo "--------------------------------------------"
echo "Download the dump folder from github"
echo "--------------------------------------------"

response=$(curl -L \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/"$USERNAME"/cms/contents/dump?ref="$REF_NAME")

rm -rf /root/dump-"$REF_NAME"
mkdir -p /root/dump-"$REF_NAME"

objects=$(echo "$response" | jq -c '.[]')
for obj in $objects; do
  download_url=$(echo "$obj" | jq -r '.download_url')
  name=$(echo "$obj" | jq -r '.name')
  curl -L "$download_url" -o "/root/dump-$REF_NAME/$name"
done


echo "--------------------------------------------"
echo "Start DB Service"
echo "--------------------------------------------"

docker service rm db-"$REF_NAME" || true
sleep 10

docker volume rm --force data-"$REF_NAME" || true
docker volume prune --all --force || true
docker network create --driver overlay "$REF_NAME"-branch || true

if ! docker service create \
  --replicas 1 \
  --name db-"$REF_NAME" \
  --network "$REF_NAME"-branch \
  --env MONGO_INITDB_DATABASE="$MONGO_INITDB_DATABASE" \
  --env MONGO_INITDB_ROOT_USERNAME="$MONGO_INITDB_ROOT_USERNAME" \
  --env MONGO_INITDB_ROOT_PASSWORD="$MONGO_INITDB_ROOT_PASSWORD" \
  --env MONGO_DB_USER="$MONGO_DB_USER" \
  --env MONGO_DB_PASS="$MONGO_DB_PASS" \
  --env MONGO_DB_NAME="$MONGO_DB_NAME" \
  --mount type=volume,source=data-"$REF_NAME",target=/data/db \
  --mount type=bind,readonly=true,source="$SCRIPT_PATH"/mongo-init.js,target=/docker-entrypoint-initdb.d/mongo-init.js \
  mongo:7.0.2; then
    echo "Service 'db-$REF_NAME' creation failed."
    Cleanup
    exit 1
fi

echo "--------------------------------------------"
echo "Restore the dump"
echo "--------------------------------------------"

for con in $(docker ps -q -f name=db-"$REF_NAME"); do
  docker exec "$con" mkdir -p /tmp/dump-"$REF_NAME"
  docker cp /root/dump-"$REF_NAME"/. "$con":/tmp/dump-"$REF_NAME"/

  # shellcheck disable=SC2045
  for file in $(ls /root/dump-"$REF_NAME"); do
    echo "import $file ..."
    if ! docker exec "$con" mongoimport \
      --drop \
      --username "$MONGO_INITDB_ROOT_USERNAME" \
      --password "$MONGO_INITDB_ROOT_PASSWORD" \
      --authenticationDatabase admin \
      --db "$MONGO_DB_NAME" \
      --collection "$(basename "$file" | cut -d. -f1)" \
      --file /tmp/dump-"$REF_NAME"/"$file" \
      --mode upsert; then
      Cleanup
      exit 1
    fi
  done
done

echo "--------------------------------------------"
echo "Start CMS Service"
echo "--------------------------------------------"

docker service rm cms-"$REF_NAME" || true
sleep 10

docker rmi --force ghcr.io/"$USERNAME"/"$IMAGE":"$REF_NAME"
docker network create --driver overlay infra || true

if ! docker service create \
  --name cms-"$REF_NAME" \
  --replicas 3 \
  --network "$REF_NAME"-branch \
  --network infra \
  --env PAYLOAD_SECRET="$PAYLOAD_SECRET" \
  --env MONGO_PROD_URL=db-"$REF_NAME":27017 \
  --env MONGO_DB_NAME="$MONGO_DB_NAME" \
  --env MONGO_DB_USER="$MONGO_DB_USER" \
  --env MONGO_DB_PASS="$MONGO_DB_PASS" \
  --env STAGE="$REF_NAME" \
  --with-registry-auth \
  ghcr.io/"$USERNAME"/"$IMAGE":"$REF_NAME"; then
  echo "CMS service error"
  Cleanup
  exit 1;
fi

echo "--------------------------------------------"
echo "Start nginx proxy"
echo "--------------------------------------------"

docker service rm proxy || true
sleep 10

if ! docker service create \
  --name proxy \
  --replicas 1 \
  --network infra \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,readonly=true,source="$SCRIPT_PATH"/Caddyfile,target=/etc/caddy/Caddyfile \
  --mount type=volume,source=caddy_data,target=/data \
  caddy:2.8-alpine; then
  echo "proxy service error"
  Cleanup
  exit 1;
fi

Cleanup