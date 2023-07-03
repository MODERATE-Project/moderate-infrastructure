# Install package requirements

import subprocess
import sys

_REQUIREMENTS = ["coloredlogs==15.0.1", "psycopg[binary]==3.1.9"]


def install(package):
    print("Installing", package)
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-U", package])


for package in _REQUIREMENTS:
    install(package)

# Create the PostGIS extensions

import logging
import os
import sys

import coloredlogs
import psycopg

_POSTGRES_URL = os.getenv("POSTGRES_URL")
assert _POSTGRES_URL, "POSTGRES_URL environment variable is required"

_logger = logging.getLogger(__name__)


def main():
    _logger.info("Creating PostGIS extensions on: %s", _POSTGRES_URL)

    with psycopg.connect(_POSTGRES_URL) as conn:
        with conn.cursor() as cur:
            cmds = [
                "CREATE EXTENSION IF NOT EXISTS postgis;",
                "CREATE EXTENSION IF NOT EXISTS postgis_topology;",
            ]

            for cmd in cmds:
                _logger.info("Executing: %s", cmd)
                cur.execute(cmd)

            conn.commit()


if __name__ == "__main__":
    coloredlogs.install(level=logging.DEBUG)

    try:
        main()
    except:
        _logger.error("Critical error", exc_info=True)
        sys.exit(1)
