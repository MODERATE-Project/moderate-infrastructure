#!/usr/bin/env bash
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
    --set=keycloak_password="$KEYCLOAK_DB_PASSWORD" \
    --set=openmetadata_password="$OPENMETADATA_DB_PASSWORD" \
    --set=api_password="$API_DB_PASSWORD" \
    --set=dagster_password="$DAGSTER_DB_PASSWORD" <<'SQL'
CREATE USER keycloak WITH PASSWORD :'keycloak_password';
CREATE DATABASE keycloak OWNER keycloak;
CREATE USER openmetadata WITH PASSWORD :'openmetadata_password';
CREATE DATABASE openmetadata OWNER openmetadata;
CREATE USER moderateapi WITH PASSWORD :'api_password';
CREATE DATABASE moderateapi OWNER moderateapi;
-- Workflows create their own state database using this role.
CREATE USER dagster WITH CREATEDB PASSWORD :'dagster_password';
-- OpenMetadata profiling reads tables across the platform databases.
GRANT pg_read_all_data TO dagster;
CREATE DATABASE dagster OWNER dagster;
\connect moderateapi
CREATE EXTENSION pg_trgm;
CREATE EXTENSION btree_gin;
SQL
