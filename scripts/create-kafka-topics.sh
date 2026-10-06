#!/usr/bin/env bash
set -euo pipefail

for topic in data-ingestion-trigger raw sample valid invalid validation unmatched-json-requests; do
    kafka-topics --bootstrap-server kafka:9092 --create --if-not-exists \
        --topic "$topic" --partitions 1 --replication-factor 1
done
