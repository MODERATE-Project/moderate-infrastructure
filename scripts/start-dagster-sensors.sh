#!/usr/bin/env bash
# Enable ingestion schedules when the OpenMetadata bot token is configured.
set -euo pipefail

for sensor in matrix_profile_messages_sensor keycloak_user_sensor platform_api_asset_object_sensor; do
    dagster sensor start "$sensor" -w "$DAGSTER_HOME/workspace.yaml"
done

schedule_action=stop
if [[ -n ${OPEN_METADATA_TOKEN:-} ]]; then
    schedule_action=start
fi

for schedule in postgres_ingestion_job_schedule datalake_ingestion_job_schedule; do
    dagster schedule "$schedule_action" "$schedule" -w "$DAGSTER_HOME/workspace.yaml"
done
