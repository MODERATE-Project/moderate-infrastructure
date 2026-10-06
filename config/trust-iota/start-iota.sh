#!/usr/bin/env bash
set -euo pipefail

# Disable synthetic traffic, which otherwise grows the database by five blocks/s.
sed -i 's/--spammer.autostart=true/--spammer.autostart=false/' /etc/supervisor/conf.d/supervisord.conf
exec /usr/bin/supervisord
