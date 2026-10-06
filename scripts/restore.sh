#!/usr/bin/env bash
# Restores backup from backup.sh to a clean host, then starts the stack.

set -euo pipefail

require_empty_host() {
    local backup_directory=$1
    local existing_volumes

    if [[ -e .env || -e secrets ]]; then
        echo "Found an existing installation. Restore needs an empty host." >&2
        exit 1
    fi

    existing_volumes=$(docker compose --env-file "$backup_directory/.env" volumes --format '{{.Name}}')
    if [[ -n $existing_volumes ]]; then
        echo "Found an existing installation. Restore needs an empty host." >&2
        exit 1
    fi
}

restore_volumes() {
    local backup_directory=$1
    local archive volume

    shopt -s nullglob
    for archive in "$backup_directory"/volumes/*.tar.gz; do
        volume=$(basename "$archive" .tar.gz)
        docker run --rm -i -v "$volume:/data" debian:12-slim \
            tar --numeric-owner -C /data -xzf - <"$archive"
    done
}

main() {
    cd "$(dirname "$0")/.."

    local backup_directory
    backup_directory=${1:?usage: restore.sh backups/<timestamp>}
    require_empty_host "$backup_directory"

    umask 077
    cp -p "$backup_directory/.env" .env
    cp -Rp "$backup_directory/secrets" secrets

    # Create the volumes with their Compose labels before filling them.
    docker compose create
    restore_volumes "$backup_directory"
    docker compose up -d --wait
}

main "$@"
