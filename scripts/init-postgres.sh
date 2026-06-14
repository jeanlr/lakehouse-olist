#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname postgres <<-EOSQL

SELECT 'CREATE DATABASE metabase'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'metabase'
)\gexec

SELECT 'CREATE DATABASE hive_metastore'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'hive_metastore'
)\gexec

EOSQL