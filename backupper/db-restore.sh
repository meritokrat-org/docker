#!/usr/bin/env bash

deploy() {
  local \
    database='meritokrat' \
    user='meritokrat' \
    password='RRcylF0M' \
    DB_BACKUP="$1"

  docker exec -u postgres postgres psql \
    -c "DROP DATABASE IF EXISTS ${database};" \
    -c "CREATE DATABASE ${database};" \
    -c "DROP USER IF EXISTS ${user};" \
    -c "CREATE USER ${user} WITH PASSWORD '${password}';" \
    -c "GRANT ALL PRIVILEGES ON DATABASE ${database} TO ${user};"

  docker exec -i -u postgres postgres psql -d ${database} <"${DB_BACKUP}"
}

#docker-compose -f /home/modelsua/docker/docker-compose.yaml exec -T -u postgres db psql -d ${database} < "${DB_BACKUP}"
