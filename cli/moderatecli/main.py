import enum
import os

import coloredlogs
import typer
from typing_extensions import Annotated

import moderatecli.kc
import moderatecli.kc.flows
import moderatecli.postgis


class Variables(str, enum.Enum):
    POSTGRES_URL = "POSTGRES_URL"
    KEYCLOAK_ADMIN_USER = "KEYCLOAK_ADMIN_USER"
    KEYCLOAK_ADMIN_PASS = "KEYCLOAK_ADMIN_PASS"
    KEYCLOAK_URL = "KEYCLOAK_URL"
    MODERATE_REALM = "MODERATE_REALM"
    APISIX_CLIENT_ID = "APISIX_CLIENT_ID"
    APISIX_CLIENT_SECRET = "APISIX_CLIENT_SECRET"
    APISIX_CLIENT_RESOURCE_YATAI = "APISIX_CLIENT_RESOURCE_YATAI"
    APISIX_CLIENT_RESOURCE_MODERATE_API = "APISIX_CLIENT_RESOURCE_MODERATE_API"
    APISIX_RESOURCES_TYPE = "APISIX_RESOURCES_TYPE"
    OPEN_METADATA_CLIENT_ID = "OPEN_METADATA_CLIENT_ID"
    OPEN_METADATA_CLIENT_SECRET = "OPEN_METADATA_CLIENT_SECRET"
    OPEN_METADATA_ROOT_URL = "OPEN_METADATA_ROOT_URL"


class Defaults(str, enum.Enum):
    KEYCLOAK_ADMIN_USER = "admin"
    KEYCLOAK_URL = "https://keycloak.moderate.cloud"
    MODERATE_REALM = "moderate"
    APISIX_CLIENT_ID = "apisix"
    APISIX_CLIENT_RESOURCE_YATAI = "yatai"
    APISIX_CLIENT_RESOURCE_MODERATE_API = "moderateapi"
    APISIX_RESOURCES_TYPE = "urn:apisix:resources:default"
    OPEN_METADATA_CLIENT_ID = "open-metadata"


app = typer.Typer()


@app.command()
def enable_postgis(
    postgres_url: Annotated[str, typer.Argument(envvar=Variables.POSTGRES_URL.value)],
):
    """Enable PostGIS extensions on the database."""

    moderatecli.postgis.enable_postgis(postgres_url=postgres_url)


@app.command()
def create_keycloak_realm(
    keycloak_admin_pass: Annotated[
        str, typer.Argument(envvar=Variables.KEYCLOAK_ADMIN_PASS.value)
    ],
    keycloak_url: Annotated[
        str, typer.Argument(envvar=Variables.KEYCLOAK_URL.value)
    ] = Defaults.KEYCLOAK_URL.value,
    keycloak_admin_user: Annotated[
        str, typer.Argument(envvar=Variables.KEYCLOAK_ADMIN_USER.value)
    ] = Defaults.KEYCLOAK_ADMIN_USER.value,
    moderate_realm: Annotated[
        str, typer.Argument(envvar=Variables.MODERATE_REALM.value)
    ] = Defaults.MODERATE_REALM.value,
):
    """Create the main Keycloak realm for MODERATE."""

    keycloak_admin = moderatecli.kc.login_admin(
        keycloak_url=keycloak_url,
        keycloak_admin_user=keycloak_admin_user,
        keycloak_admin_pass=keycloak_admin_pass,
    )

    moderatecli.kc.create_moderate_realm(
        keycloak_admin=keycloak_admin,
        realm_name=moderate_realm,
    )


@app.command()
def create_apisix_client(
    keycloak_admin_pass: Annotated[
        str, typer.Argument(envvar=Variables.KEYCLOAK_ADMIN_PASS.value)
    ],
    apisix_client_secret: Annotated[
        str, typer.Argument(envvar=Variables.APISIX_CLIENT_SECRET.value)
    ],
    moderate_realm: Annotated[
        str, typer.Argument(envvar=Variables.MODERATE_REALM.value)
    ] = Defaults.MODERATE_REALM.value,
    keycloak_url: Annotated[
        str, typer.Argument(envvar=Variables.KEYCLOAK_URL.value)
    ] = Defaults.KEYCLOAK_URL.value,
    keycloak_admin_user: Annotated[
        str, typer.Argument(envvar=Variables.KEYCLOAK_ADMIN_USER.value)
    ] = Defaults.KEYCLOAK_ADMIN_USER.value,
    apisix_client_id: Annotated[
        str, typer.Argument(envvar=Variables.APISIX_CLIENT_ID.value)
    ] = Defaults.APISIX_CLIENT_ID.value,
    apisix_client_resource_yatai: Annotated[
        str, typer.Argument(envvar=Variables.APISIX_CLIENT_RESOURCE_YATAI.value)
    ] = Defaults.APISIX_CLIENT_RESOURCE_YATAI.value,
    apisix_client_resource_moderate_api: Annotated[
        str, typer.Argument(envvar=Variables.APISIX_CLIENT_RESOURCE_MODERATE_API.value)
    ] = Defaults.APISIX_CLIENT_RESOURCE_MODERATE_API.value,
    apisix_resources_type: Annotated[
        str, typer.Argument(envvar=Variables.APISIX_RESOURCES_TYPE.value)
    ] = Defaults.APISIX_RESOURCES_TYPE.value,
):
    """Create the APISIX client."""

    keycloak_admin = moderatecli.kc.login_admin(
        keycloak_url=keycloak_url,
        keycloak_admin_user=keycloak_admin_user,
        keycloak_admin_pass=keycloak_admin_pass,
        realm_name=moderate_realm,
    )

    moderatecli.kc.create_apisix_client(
        keycloak_admin=keycloak_admin,
        client_id=apisix_client_id,
        client_secret=apisix_client_secret,
        moderate_api_resource=apisix_client_resource_moderate_api,
        yatai_resource=apisix_client_resource_yatai,
        resources_type=apisix_resources_type,
    )


@app.command()
def create_open_metadata_client(
    keycloak_admin_pass: Annotated[
        str, typer.Argument(envvar=Variables.KEYCLOAK_ADMIN_PASS.value)
    ],
    open_metadata_client_secret: Annotated[
        str, typer.Argument(envvar=Variables.OPEN_METADATA_CLIENT_SECRET.value)
    ],
    open_metadata_root_url: Annotated[
        str, typer.Argument(envvar=Variables.OPEN_METADATA_ROOT_URL.value)
    ],
    moderate_realm: Annotated[
        str, typer.Argument(envvar=Variables.MODERATE_REALM.value)
    ] = Defaults.MODERATE_REALM.value,
    keycloak_url: Annotated[
        str, typer.Argument(envvar=Variables.KEYCLOAK_URL.value)
    ] = Defaults.KEYCLOAK_URL.value,
    keycloak_admin_user: Annotated[
        str, typer.Argument(envvar=Variables.KEYCLOAK_ADMIN_USER.value)
    ] = Defaults.KEYCLOAK_ADMIN_USER.value,
    open_metadata_client_id: Annotated[
        str, typer.Argument(envvar=Variables.OPEN_METADATA_CLIENT_ID.value)
    ] = Defaults.OPEN_METADATA_CLIENT_ID.value,
):
    """Create the Open Metadata client."""

    keycloak_admin = moderatecli.kc.login_admin(
        keycloak_url=keycloak_url,
        keycloak_admin_user=keycloak_admin_user,
        keycloak_admin_pass=keycloak_admin_pass,
        realm_name=moderate_realm,
    )

    moderatecli.kc.create_open_metadata_client(
        keycloak_admin=keycloak_admin,
        client_id=open_metadata_client_id,
        client_secret=open_metadata_client_secret,
        root_url=open_metadata_root_url,
    )

    role_name = moderatecli.kc.flows.create_role_for_client_access(
        keycloak_admin=keycloak_admin, client_id=open_metadata_client_id
    )

    moderatecli.kc.flows.create_role_based_browser_flow_draft(
        keycloak_admin=keycloak_admin,
        role_name=role_name,
        bind_to_client_id=open_metadata_client_id,
    )


def main():
    coloredlogs.install(level=os.getenv("LOG_LEVEL", "DEBUG"))
    app()


if __name__ == "__main__":
    main()
