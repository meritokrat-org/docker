#!/bin/bash
set -e

echo "Creating database and user..."

POSTGRES_DB=meritokrat
POSTGRES_USER=meritokrat
POSTGRES_PASSWORD=RRcylF0M

PGPASSWORD=123 psql -v ON_ERROR_STOP=1 -U meritokrat <<-EOSQL
    CREATE DATABASE ${POSTGRES_DB};
    CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};
EOSQL

#echo "Downloading dump..."
#curl -L -o /tmp/dump.sql https://example.com/dump.sql
#
#echo "Importing dump..."
#psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname=mydb -f /tmp/dump.sql
#
#echo "Cleaning up..."
#rm /tmp/dump.sql
