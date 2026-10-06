#!/usr/bin/env bash
# Backup: Stops the stack, saves .env, secrets/, image refs, Git commit,
# and one tar per volume to backups/<timestamp>. Restarts stack on exit.

set -euo pipefail

save_metadata() {
    local backup_directory=$1

    mkdir -p "$backup_directory/volumes"
    cp -p .env "$backup_directory/"
    cp -Rp secrets "$backup_directory/"
    docker compose config --images | sort -u >"$backup_directory/images.txt"
    git rev-parse HEAD >"$backup_directory/commit"
}

archive_volumes() {
    local backup_directory=$1
    local volume_names volume

    volume_names=$(docker compose volumes --format '{{.Name}}')
    while IFS= read -r volume; do
        if [[ -z $volume ]]; then
            continue
        fi

        # --numeric-owner keeps container UIDs (e.g. 999 for Postgres) on restore.
        docker run --rm -v "$volume:/data:ro" debian:12-slim \
            tar --numeric-owner -C /data -czf - . >"$backup_directory/volumes/$volume.tar.gz"
    done <<<"$volume_names"
}

restart_stack() {
    docker compose up -d --wait
}

main() {
    cd "$(dirname "$0")/.."
    umask 077

    local backup_directory
    backup_directory=backups/$(date -u +%Y%m%dT%H%M%SZ)
    save_metadata "$backup_directory"

    # Set before stopping, so a failed stop still restarts what was stopped.
    trap restart_stack EXIT
    docker compose stop

    archive_volumes "$backup_directory"
    echo "Backup written to $backup_directory"
}

main "$@"
