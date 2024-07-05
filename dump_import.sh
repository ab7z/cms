for file in $(find /dump | tail -n +2)
do
  echo "importing $(basename "${file}" | cut -d. -f1) ..."
  if ! mongoimport \
    --drop \
    --quiet \
    --username="${MONGO_INITDB_ROOT_USERNAME}" \
    --password="${MONGO_INITDB_ROOT_PASSWORD}" \
    --authenticationDatabase=admin \
    --db="${MONGO_DB_NAME}" \
    --host=localhost:27017 \
    --collection="$(basename "${file}" | cut -d. -f1)" \
    --file="${file}" \
    --mode=upsert; then
      exit 1
  fi
done
