#!/bin/bash

echo "--------------------------------------------"
echo "Trigger netlify build"
echo "--------------------------------------------"

trigger_url=$MAIN_TRIGGER
if [ "$REF_NAME" = "dev" ]; then
  trigger_url=$DEV_TRIGGER
elif [ "$REF_NAME" = "staging" ]; then
  trigger_url=$STAGING_TRIGGER
fi

curl -X POST -d '{}' "$trigger_url"
