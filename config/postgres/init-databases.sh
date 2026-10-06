#!/usr/bin/env bash
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
    --set=keycloak_password="$KEYCLOAK_DB_PASSWORD" \
    --set=openmetadata_password="$OPENMETADATA_DB_PASSWORD" \
    --set=api_password="$API_DB_PASSWORD" <<'SQL'
CREATE USER keycloak WITH PASSWORD :'keycloak_password';
CREATE DATABASE keycloak OWNER keycloak;
CREATE USER openmetadata WITH PASSWORD :'openmetadata_password';
CREATE DATABASE openmetadata OWNER openmetadata;
CREATE USER moderateapi WITH PASSWORD :'api_password';
CREATE DATABASE moderateapi OWNER moderateapi;
\connect moderateapi
CREATE EXTENSION pg_trgm;
CREATE EXTENSION btree_gin;
SQL
