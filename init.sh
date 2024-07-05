#!/bin/bash

# Path to the .env file
ENV_FILE="$(pwd)/.env"

# Check if the .env file exists
if [ -e "$ENV_FILE" ]; then
  echo "CMS .env file exists"
  source .env
else
  echo "ERROR: .env file does not exist"
  exit 1
fi

# Set Git configuration core.hooksPath to .git/hooks
git config core.hooksPath "$(pwd)/.git/hooks"
rm -rf "$(pwd)/.git/hooks"/*

touch "$(pwd)/.git/hooks/post-checkout"

{
  echo "#!/bin/bash"
  echo ""
  echo "bash $(pwd)/git-hooks/post-checkout.sh"
} >>"$(pwd)/.git/hooks/post-checkout"

chmod +x "$(pwd)/git-hooks/post-checkout.sh"
chmod +x "$(pwd)/.git/hooks/post-checkout"

container_name="cms-db"
project_name="hz-cms"

docker compose --file compose.yaml --project-name $project_name down --remove-orphans --volumes
docker volume prune --filter "label=com.docker.compose.project=$project_name" --force

docker compose --file compose.yaml --project-name $project_name up --detach --force-recreate --remove-orphans --build
docker cp ./dump/ $container_name:dump/
docker cp dump_import.sh $container_name:dump_import.sh

echo "wait for docker compose..."
sleep 10

if ! docker exec $container_name bash dump_import.sh; then
  exit 1
fi

# Install dependencies
pnpm install
