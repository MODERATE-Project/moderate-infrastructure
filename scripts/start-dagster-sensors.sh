#!/usr/bin/env bash
# Re-enable the operational sensors on deployment; leave schedules untouched.
set -euo pipefail

for sensor in matrix_profile_messages_sensor keycloak_user_sensor platform_api_asset_object_sensor; do
    dagster sensor start "$sensor" -w "$DAGSTER_HOME/workspace.yaml"
done
