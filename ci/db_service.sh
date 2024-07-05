#!/bin/bash

echo "--------------------------------------------"
echo "Start DB Service"
echo "--------------------------------------------"

echo "Create service 'db-$REF_NAME'"
docker service rm db-"$REF_NAME" || true
sleep 10

docker volume rm --force data-"$REF_NAME" || true
docker volume prune --all --force || true

docker network create --driver overlay "$REF_NAME"-branch || true

SCRIPT_PATH="$(dirname "$0")"

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
      exit 1
    fi
  done
done