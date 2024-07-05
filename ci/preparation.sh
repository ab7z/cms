#!/bin/bash

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
