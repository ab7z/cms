#!/bin/bash

echo "--------------------------------------------"
echo "Start CMS Service"
echo "--------------------------------------------"

docker service rm cms-"$REF_NAME" || true
sleep 10

docker rmi --force ghcr.io/"$USERNAME"/"$IMAGE":"$REF_NAME"
docker network create --driver overlay cms || true

if ! docker service create \
  --name cms-"$REF_NAME" \
  --replicas 3 \
  --network "$REF_NAME"-branch \
  --network cms \
  --env PAYLOAD_SECRET="$PAYLOAD_SECRET" \
  --env MONGO_PROD_URL=db-"$REF_NAME":27017 \
  --env MONGO_DB_NAME="$MONGO_DB_NAME" \
  --env MONGO_DB_USER="$MONGO_DB_USER" \
  --env MONGO_DB_PASS="$MONGO_DB_PASS" \
  --env STAGE="$REF_NAME" \
  --with-registry-auth \
  ghcr.io/"$USERNAME"/"$IMAGE":"$REF_NAME"; then
  echo "CMS service error"
  exit 1;
fi