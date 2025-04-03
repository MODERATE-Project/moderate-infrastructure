#!/bin/bash

# Cloud SQL Dump Loader
# ====================
# This script loads a SQL dump file into a Google Cloud SQL instance.
# It handles both local SQL files and remote URLs, and supports both
# standard SQL and PostgreSQL custom-format dumps.
#
# Required Environment Variables:
# - GCP_PROJECT_ID: Google Cloud project ID
# - CLOUD_SQL_INSTANCE: Cloud SQL instance name (e.g., moderate-postgres)
# - DB_NAME: Target database name
# - SQL_DUMP_FILE: Path to SQL dump file or URL
# - DB_USER: Database user
# - DB_PASSWORD: Database password
#
# Optional Environment Variables:
# - REGION: Cloud SQL region (default: europe-west1)
# - PROXY_PORT: Local port for Cloud SQL proxy (default: 5432)
# - DB_PORT: Database port (default: 5432)
# - PROXY_CONTAINER_NAME: Name for the Cloud SQL proxy container (default: cloud-sql-proxy)
# - FORCE_RECREATE: Whether to automatically recreate the database if it exists (default: false)

set -euo pipefail

# Required environment variables
: "${GCP_PROJECT_ID:?Environment variable GCP_PROJECT_ID is required}"
: "${CLOUD_SQL_INSTANCE:?Environment variable CLOUD_SQL_INSTANCE is required}"
: "${DB_NAME:?Environment variable DB_NAME is required}"
: "${SQL_DUMP_FILE:?Environment variable SQL_DUMP_FILE is required}"
: "${DB_USER:?Environment variable DB_USER is required}"
: "${DB_PASSWORD:?Environment variable DB_PASSWORD is required}"

# Optional environment variables with defaults
: "${REGION:=europe-west1}"
: "${PROXY_PORT:=5432}"
: "${DB_PORT:=5432}"
: "${PROXY_CONTAINER_NAME:=cloud-sql-proxy}"
: "${FORCE_RECREATE:=false}"

function log_info() {
    echo "🔹 $1"
}

function log_success() {
    echo "✅ $1"
}

function log_error() {
    echo "❌ $1" >&2
}

function log_warning() {
    echo "⚠️  $1" >&2
}

function log_step() {
    echo "🔄 $1"
}

# Function to clean up temporary resources
function cleanup() {
    log_step "Cleaning up..."

    # Stop and remove the proxy container if it exists
    if docker ps -a --format '{{.Names}}' | grep -q "^${PROXY_CONTAINER_NAME}$"; then
        log_info "Stopping and removing Cloud SQL proxy container"
        docker stop ${PROXY_CONTAINER_NAME} 2>/dev/null || true
        docker rm ${PROXY_CONTAINER_NAME} 2>/dev/null || true
    fi

    # Remove temporary dump file if it exists
    if [ -n "${TEMP_DUMP_FILE:-}" ] && [ -f "${TEMP_DUMP_FILE}" ]; then
        log_info "Removing temporary SQL dump file"
        rm -f "${TEMP_DUMP_FILE}"
    fi

    # Remove temporary credential file if it exists
    if [ -n "${TEMP_CREDS_DIR:-}" ] && [ -d "${TEMP_CREDS_DIR}" ]; then
        log_info "Removing temporary credentials directory"
        rm -rf "${TEMP_CREDS_DIR}"
    fi
}

# Set up trap to clean up resources on exit
trap cleanup EXIT

# Print script header
echo ""
echo "🚀 Cloud SQL Dump Loader"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Log configuration (excluding sensitive information)
log_info "Configuration:"
log_info "  Project ID: ${GCP_PROJECT_ID}"
log_info "  Cloud SQL Instance: ${CLOUD_SQL_INSTANCE}"
log_info "  Database Name: ${DB_NAME}"
log_info "  SQL Dump File: ${SQL_DUMP_FILE}"
log_info "  Database User: ${DB_USER}"
log_info "  Region: ${REGION}"
log_info "  Proxy Port: ${PROXY_PORT}"
log_info "  Database Port: ${DB_PORT}"
log_info "  Proxy Container: ${PROXY_CONTAINER_NAME}"
log_info "  Force Recreate: ${FORCE_RECREATE}"
echo ""

log_info "Connecting to Cloud SQL instance ${CLOUD_SQL_INSTANCE} and loading SQL dump"

# Check if SQL_DUMP_FILE is an HTTP URL and download if necessary
if [[ "${SQL_DUMP_FILE}" =~ ^https?:// ]]; then
    log_step "SQL dump is a URL. Downloading..."
    TEMP_DUMP_FILE=$(mktemp)
    if curl -L -f -s -o "${TEMP_DUMP_FILE}" "${SQL_DUMP_FILE}"; then
        log_success "Successfully downloaded SQL dump to temporary file"
        SQL_DUMP_FILE="${TEMP_DUMP_FILE}"
    else
        log_error "Failed to download SQL dump from ${SQL_DUMP_FILE}"
        rm -f "${TEMP_DUMP_FILE}"
        exit 1
    fi
else
    # Check if local SQL dump file exists
    if [ ! -f "${SQL_DUMP_FILE}" ]; then
        log_error "SQL dump file ${SQL_DUMP_FILE} does not exist"
        exit 1
    fi
fi

log_step "Cleaning up any existing proxy container..."
docker rm -f ${PROXY_CONTAINER_NAME} 2>/dev/null || true

log_step "Starting Cloud SQL Proxy using Docker..."

# Define credentials paths
GCLOUD_CONFIG_DIR="${HOME}/.config/gcloud"
ADC_FILE="${GCLOUD_CONFIG_DIR}/application_default_credentials.json"

# Check if application default credentials exist
if [ ! -f "${ADC_FILE}" ]; then
    log_error "Application Default Credentials not found at ${ADC_FILE}"
    log_info "Please run 'gcloud auth application-default login' first"
    exit 1
fi

# Create a temporary directory with proper permissions for credentials
TEMP_CREDS_DIR=$(mktemp -d)
TEMP_ADC_FILE="${TEMP_CREDS_DIR}/application_default_credentials.json"

# Copy and ensure correct permissions on the credentials file
cp "${ADC_FILE}" "${TEMP_ADC_FILE}"
chmod 644 "${TEMP_ADC_FILE}"

log_info "Prepared credentials for container access"

# Connection string must be in the format: PROJECT_ID:REGION:INSTANCE_NAME
INSTANCE_CONNECTION_NAME="${GCP_PROJECT_ID}:${REGION}:${CLOUD_SQL_INSTANCE}"
log_info "Using connection name: ${INSTANCE_CONNECTION_NAME}"

# Start the Cloud SQL proxy container
if ! docker run --name ${PROXY_CONTAINER_NAME} \
    -d \
    -p ${PROXY_PORT}:5432 \
    -v "${TEMP_CREDS_DIR}:/credentials" \
    -e GOOGLE_APPLICATION_CREDENTIALS="/credentials/application_default_credentials.json" \
    gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.6.0 \
    --address 0.0.0.0 \
    --port 5432 \
    ${INSTANCE_CONNECTION_NAME}; then
    log_error "Failed to start Cloud SQL proxy container"
    exit 1
fi

log_step "Waiting for proxy to be ready..."
sleep 10

if ! docker ps | grep -q ${PROXY_CONTAINER_NAME}; then
    log_error "Cloud SQL Proxy container failed to start. Checking logs:"
    docker logs ${PROXY_CONTAINER_NAME}
    exit 1
fi

log_step "Preparing database ${DB_NAME}..."
export PGPASSWORD="${DB_PASSWORD}"

# Check if database exists
DB_EXISTS=$(psql -h localhost -p ${PROXY_PORT} -U ${DB_USER} -d postgres -t -c "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}';" | xargs)

# Function to recreate database
function recreate_database() {
    log_step "Dropping database ${DB_NAME}..."
    if ! psql -h localhost -p ${PROXY_PORT} -U ${DB_USER} -d postgres -c "DROP DATABASE IF EXISTS ${DB_NAME};"; then
        log_error "Failed to drop database ${DB_NAME}"
        exit 1
    fi

    log_step "Creating database ${DB_NAME}..."
    if ! psql -h localhost -p ${PROXY_PORT} -U ${DB_USER} -d postgres -c "CREATE DATABASE ${DB_NAME};"; then
        log_error "Failed to create database ${DB_NAME}"
        exit 1
    fi
    log_success "Database ${DB_NAME} created"
}

if [ "$DB_EXISTS" = "1" ]; then
    log_warning "Database ${DB_NAME} already exists"

    # Check if force recreate is enabled
    if [[ "${FORCE_RECREATE}" == "true" || "${FORCE_RECREATE}" == "1" ]]; then
        log_info "FORCE_RECREATE is enabled, automatically recreating database"
        recreate_database
    else
        # Ask user if they want to drop and recreate the database
        read -p "Do you want to drop and recreate the database? (y/n): " CONFIRM
        if [[ "${CONFIRM}" == "y" || "${CONFIRM}" == "Y" ]]; then
            recreate_database
        fi
    fi
else
    log_step "Creating database ${DB_NAME}..."
    if ! psql -h localhost -p ${PROXY_PORT} -U ${DB_USER} -d postgres -c "CREATE DATABASE ${DB_NAME};"; then
        log_error "Failed to create database ${DB_NAME}"
        exit 1
    fi
    log_success "Database ${DB_NAME} created"
fi

log_step "Detecting SQL dump format..."

if file ${SQL_DUMP_FILE} | grep -q "PostgreSQL custom database dump"; then
    log_info "Detected PostgreSQL custom-format dump, using pg_restore"

    # First, grant necessary privileges to make the user the owner of the database
    if ! psql -h localhost -p ${PROXY_PORT} -U ${DB_USER} -d postgres -c "ALTER DATABASE ${DB_NAME} OWNER TO ${DB_USER};"; then
        log_error "Failed to set database owner"
        exit 1
    fi

    # First pass: Create tables and schemas only
    log_step "First pass: Creating tables and schemas..."
    if ! pg_restore --no-owner --no-acl --schema-only --clean --if-exists \
        -h localhost -p ${PROXY_PORT} -U ${DB_USER} -d ${DB_NAME} ${SQL_DUMP_FILE}; then
        log_warning "Some schema objects might not have been created properly"
    fi

    # Second pass: Load data only
    log_step "Second pass: Loading data..."
    if ! pg_restore --no-owner --no-acl --data-only \
        -h localhost -p ${PROXY_PORT} -U ${DB_USER} -d ${DB_NAME} ${SQL_DUMP_FILE}; then
        log_warning "Some data might not have been loaded properly"
    fi

    # Additional step: Set search_path to include all schemas
    log_step "Setting proper search path for database..."
    if ! psql -h localhost -p ${PROXY_PORT} -U ${DB_USER} -d ${DB_NAME} -c "ALTER DATABASE ${DB_NAME} SET search_path TO public,postgres;"; then
        log_warning "Failed to set search path"
    fi
else
    log_info "Using standard SQL format with psql"
    if ! psql -h localhost -p ${PROXY_PORT} -U ${DB_USER} -d ${DB_NAME} <${SQL_DUMP_FILE}; then
        log_error "Failed to load SQL dump"
        exit 1
    fi
fi

log_success "SQL dump loaded successfully into database ${DB_NAME}"
log_success "Done! 🎉"
echo ""
