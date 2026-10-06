#!/usr/bin/env python3
"""Check Kafka polling but ignore idle status."""

import json
import time
from urllib.request import urlopen

with urlopen("http://127.0.0.1:8000/report/status", timeout=4) as response:
    status = json.load(response)
last_poll = status.get("last_poll_at")
if not status.get("kafka_connected") or last_poll is None or time.time() - last_poll > 30:
    raise SystemExit("Reporter is not polling Kafka.")
