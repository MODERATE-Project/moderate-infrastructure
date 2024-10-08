import logging

import psycopg

_logger = logging.getLogger(__name__)


def enable_postgis(postgres_url: str):
    with psycopg.connect(postgres_url) as conn:
        with conn.cursor() as cur:
            cmds = [
                "CREATE EXTENSION IF NOT EXISTS postgis;",
                "CREATE EXTENSION IF NOT EXISTS postgis_topology;",
            ]

            for cmd in cmds:
                _logger.info("Executing: %s", cmd)
                cur.execute(cmd)

            conn.commit()


def enable_extensions(postgres_url: str):
    with psycopg.connect(postgres_url) as conn:
        with conn.cursor() as cur:
            cmds = [
                "CREATE EXTENSION IF NOT EXISTS postgis;",
                "CREATE EXTENSION IF NOT EXISTS postgis_topology;",
                "CREATE EXTENSION IF NOT EXISTS pg_trgm;",
                "CREATE EXTENSION IF NOT EXISTS btree_gin;",
            ]

            for cmd in cmds:
                _logger.info("Executing: %s", cmd)
                cur.execute(cmd)

            conn.commit()
