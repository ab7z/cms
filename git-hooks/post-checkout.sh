#!/bin/bash

# Check for docker engine and docker compose v2
if ! command -v docker &>/dev/null; then
  echo "Docker is not installed. Please install Docker."
  exit 1
fi

# Check if Docker Compose is installed
docker_compose_version=$(docker compose version --short)
if [[ -z "$docker_compose_version" ]]; then
  echo "Docker Compose is not installed. Please install Docker Compose (version 2)."
  exit 1
fi

# Check if Docker Compose version is 2.x
major_version=$(echo "$docker_compose_version" | awk -F'[.]' '{print $1}')
if [[ $major_version -lt 2 ]]; then
  echo "Docker Compose version $docker_compose_version is not version 2 or higher."
  exit 1
fi

container_name="cms-db"
project_name="hz-cms"

docker compose --file compose.yaml --project-name $project_name down --remove-orphans --volumes
docker volume prune --filter "label=com.docker.compose.project=$project_name" --force

docker compose --file compose.yaml --project-name $project_name up --detach --force-recreate --remove-orphans --build
docker cp ./dump/ $container_name:dump/
docker cp dump_import.sh $container_name:dump_import.sh

echo "wait for docker compose..."
sleep 5
if ! docker exec $container_name bash dump_import.sh; then
  exit 1
fi
