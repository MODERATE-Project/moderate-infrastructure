#!/usr/bin/env bash
# Fails if a configured service has no container, or if any container isn't
# running, healthy, or (for jobs) exited successfully.

set -euo pipefail

find_services_without_container() {
    local configured_services created_services

    # `set -e` doesn't apply inside command substitutions, so return on failure.
    configured_services=$(docker compose config --services) || return
    created_services=$(docker compose ps --all --format '{{.Service}}') || return

    # Configured but never created, or removed by `task down`.
    comm -23 <(sort <<<"$configured_services") <(sort -u <<<"$created_services")
}

find_unready_services() {
    # AWK preserves empty tab-separated health fields.
    docker compose ps --all --format '{{.Service}}\t{{.State}}\t{{.Health}}\t{{.ExitCode}}' |
        awk -F '\t' '
            {
                service = $1
                state = $2
                health = $3
                exit_code = $4

                if (state == "running" && (health == "" || health == "healthy")) {
                    next
                }
                if (state == "exited" && exit_code == 0) {
                    next
                }

                print service
            }
        '
}

main() {
    cd "$(dirname "$0")/.."

    local missing_services unready_services failed_services
    missing_services=$(find_services_without_container)
    unready_services=$(find_unready_services)
    failed_services=$(printf '%s\n%s\n' "$missing_services" "$unready_services" | sed '/^$/d')
    if [[ -n $failed_services ]]; then
        printf 'Not ready:\n%s\n' "$failed_services" >&2
        exit 1
    fi
}

main "$@"
