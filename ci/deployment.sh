#!/bin/bash

echo "$TOKEN" | docker login ghcr.io -u "$USERNAME" --password-stdin

SCRIPT_PATH="$(dirname "$0")"

Cleanup () {
  docker logout ghcr.io
  docker volume prune --all --force || true
  docker system prune --force --all --volumes || true
}

if ! bash "$SCRIPT_PATH"/preparation.sh; then
  Cleanup
  exit 1
fi

if ! bash "$SCRIPT_PATH"/db_service.sh; then
  Cleanup
  exit 1
fi

if ! bash "$SCRIPT_PATH"/cms_service.sh; then
  Cleanup
  exit 1
fi

if ! bash "$SCRIPT_PATH"/proxy.sh; then
  Cleanup
  exit 1
fi

if ! bash "$SCRIPT_PATH"/netlify.sh; then
  Cleanup
  exit 1
fi

Cleanup