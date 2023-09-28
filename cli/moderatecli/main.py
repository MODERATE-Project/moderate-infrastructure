import os

import coloredlogs
import typer
from typing_extensions import Annotated

import moderatecli.keycloak
import moderatecli.postgis

app = typer.Typer()


@app.command()
def enable_postgis(
    postgres_url: Annotated[str, typer.Argument(envvar="POSTGRES_URL")],
):
    """Enable PostGIS extensions on the database."""

    moderatecli.postgis.enable_postgis(postgres_url=postgres_url)


@app.command()
def create_keycloak_entities(
    keycloak_admin_pass: Annotated[str, typer.Argument(envvar="KEYCLOAK_ADMIN_PASS")],
    apisix_client_secret: Annotated[str, typer.Argument(envvar="APISIX_CLIENT_SECRET")],
    open_metadata_client_secret: Annotated[
        str, typer.Argument(envvar="OPEN_METADATA_CLIENT_SECRET")
    ],
    open_metadata_root_url: Annotated[
        str, typer.Argument(envvar="OPEN_METADATA_ROOT_URL")
    ],
    keycloak_url: Annotated[
        str, typer.Argument(envvar="KEYCLOAK_URL")
    ] = "https://keycloak.moderate.cloud",
    keycloak_admin_user: Annotated[
        str, typer.Argument(envvar="KEYCLOAK_ADMIN_USER")
    ] = "admin",
    moderate_realm: Annotated[
        str, typer.Argument(envvar="MODERATE_REALM")
    ] = "moderate",
    apisix_client_id: Annotated[
        str, typer.Argument(envvar="APISIX_CLIENT_ID")
    ] = "apisix",
    apisix_client_resource_yatai: Annotated[
        str, typer.Argument(envvar="APISIX_CLIENT_RESOURCE_YATAI")
    ] = "yatai",
    apisix_client_resource_moderate_api: Annotated[
        str, typer.Argument(envvar="APISIX_CLIENT_RESOURCE_MODERATE_API")
    ] = "moderateapi",
    open_metadata_client_id: Annotated[
        str, typer.Argument(envvar="OPEN_METADATA_CLIENT_ID")
    ] = "openmetadata",
):
    """Create Keycloak entities."""

    moderatecli.keycloak.create_keycloak_entities(
        keycloak_url=keycloak_url,
        keycloak_admin_user=keycloak_admin_user,
        keycloak_admin_pass=keycloak_admin_pass,
        moderate_realm=moderate_realm,
        apisix_client_id=apisix_client_id,
        apisix_client_secret=apisix_client_secret,
        apisix_client_resource_yatai=apisix_client_resource_yatai,
        apisix_client_resource_moderate_api=apisix_client_resource_moderate_api,
        open_metadata_client_id=open_metadata_client_id,
        open_metadata_client_secret=open_metadata_client_secret,
        open_metadata_root_url=open_metadata_root_url,
    )


def main():
    coloredlogs.install(level=os.getenv("LOG_LEVEL", "DEBUG"))
    app()


if __name__ == "__main__":
    main()
