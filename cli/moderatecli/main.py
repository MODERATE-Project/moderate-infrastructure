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
    OPEN_METADATA_ROOT_URL = "OPEN_METADATA_ROOT_URL"
    UI_CLIENT_ID = "UI_CLIENT_ID"
    UI_WEB_ORIGINS = "UI_WEB_ORIGINS"
    UI_REDIRECT_URIS = "UI_REDIRECT_URIS"
    USER_USERNAME = "USER_USERNAME"
    USER_PASSWORD = "USER_PASSWORD"
    APISIX_API_ADMIN_ROLE = "APISIX_API_ADMIN_ROLE"


class Defaults(str, enum.Enum):
    KEYCLOAK_ADMIN_USER = "admin"
    KEYCLOAK_URL = "https://keycloak.moderate.cloud"
    MODERATE_REALM = "moderate"
    APISIX_CLIENT_ID = "apisix"
    APISIX_CLIENT_RESOURCE_YATAI = "yatai"
    APISIX_CLIENT_RESOURCE_MODERATE_API = "moderateapi"
    APISIX_RESOURCES_TYPE = "urn:apisix:resources:default"
    OPEN_METADATA_CLIENT_ID = "open-metadata"
    UI_CLIENT_ID = "ui"
    UI_WEB_ORIGINS = "https://*.moderate.cloud"
    UI_REDIRECT_URIS = "https://*.moderate.cloud/*"
    APISIX_API_ADMIN_ROLE = "api_admin"


app = typer.Typer()


class Args:
    postgres_url = Annotated[str, typer.Argument(envvar=Variables.POSTGRES_URL.value)]

    keycloak_admin_pass = Annotated[
        str, typer.Argument(envvar=Variables.KEYCLOAK_ADMIN_PASS.value)
    ]

    keycloak_url = Annotated[str, typer.Argument(envvar=Variables.KEYCLOAK_URL.value)]

    keycloak_admin_user = Annotated[
        str, typer.Argument(envvar=Variables.KEYCLOAK_ADMIN_USER.value)
    ]

    moderate_realm = Annotated[
        str, typer.Argument(envvar=Variables.MODERATE_REALM.value)
    ]

    apisix_client_secret = Annotated[
        str, typer.Argument(envvar=Variables.APISIX_CLIENT_SECRET.value)
    ]

    apisix_client_id = Annotated[
        str, typer.Argument(envvar=Variables.APISIX_CLIENT_ID.value)
    ]

    apisix_client_resource_yatai = Annotated[
        str, typer.Argument(envvar=Variables.APISIX_CLIENT_RESOURCE_YATAI.value)
    ]

    apisix_client_resource_moderate_api = Annotated[
        str, typer.Argument(envvar=Variables.APISIX_CLIENT_RESOURCE_MODERATE_API.value)
    ]

    apisix_resources_type = Annotated[
        str, typer.Argument(envvar=Variables.APISIX_RESOURCES_TYPE.value)
    ]

    apisix_api_admin_role = Annotated[
        str, typer.Argument(envvar=Variables.APISIX_API_ADMIN_ROLE.value)
    ]

    open_metadata_root_url = Annotated[
        str, typer.Argument(envvar=Variables.OPEN_METADATA_ROOT_URL.value)
    ]

    open_metadata_client_id = Annotated[
        str, typer.Argument(envvar=Variables.OPEN_METADATA_CLIENT_ID.value)
    ]

    ui_client_id = Annotated[str, typer.Argument(envvar=Variables.UI_CLIENT_ID.value)]

    ui_web_origins = Annotated[
        str, typer.Argument(envvar=Variables.UI_WEB_ORIGINS.value)
    ]

    ui_redirect_uris = Annotated[
        str, typer.Argument(envvar=Variables.UI_REDIRECT_URIS.value)
    ]

    user_username = Annotated[str, typer.Argument(envvar=Variables.USER_USERNAME.value)]
    user_password = Annotated[str, typer.Argument(envvar=Variables.USER_PASSWORD.value)]


@app.command()
def enable_postgis(postgres_url: Args.postgres_url):
    """Enable PostGIS extensions on the database."""

    moderatecli.postgis.enable_postgis(postgres_url=postgres_url)


@app.command()
def create_keycloak_realm(
    keycloak_admin_pass: Args.keycloak_admin_pass,
    keycloak_url: Args.keycloak_url = Defaults.KEYCLOAK_URL.value,
    keycloak_admin_user: Args.keycloak_admin_user = Defaults.KEYCLOAK_ADMIN_USER.value,
    moderate_realm: Args.moderate_realm = Defaults.MODERATE_REALM.value,
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
    keycloak_admin_pass: Args.keycloak_admin_pass,
    apisix_client_secret: Args.apisix_client_secret,
    moderate_realm: Args.moderate_realm = Defaults.MODERATE_REALM.value,
    keycloak_url: Args.keycloak_url = Defaults.KEYCLOAK_URL.value,
    keycloak_admin_user: Args.keycloak_admin_user = Defaults.KEYCLOAK_ADMIN_USER.value,
    apisix_client_id: Args.apisix_client_id = Defaults.APISIX_CLIENT_ID.value,
    apisix_client_resource_yatai: Args.apisix_client_resource_yatai = Defaults.APISIX_CLIENT_RESOURCE_YATAI.value,
    apisix_client_resource_moderate_api: Args.apisix_client_resource_moderate_api = Defaults.APISIX_CLIENT_RESOURCE_MODERATE_API.value,
    apisix_resources_type: Args.apisix_resources_type = Defaults.APISIX_RESOURCES_TYPE.value,
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
    keycloak_admin_pass: Args.keycloak_admin_pass,
    open_metadata_root_url: Args.open_metadata_root_url,
    moderate_realm: Args.moderate_realm = Defaults.MODERATE_REALM.value,
    keycloak_url: Args.keycloak_url = Defaults.KEYCLOAK_URL.value,
    keycloak_admin_user: Args.keycloak_admin_user = Defaults.KEYCLOAK_ADMIN_USER.value,
    open_metadata_client_id: Args.open_metadata_client_id = Defaults.OPEN_METADATA_CLIENT_ID.value,
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


@app.command()
def create_ui_client(
    keycloak_admin_pass: Args.keycloak_admin_pass,
    moderate_realm: Args.moderate_realm = Defaults.MODERATE_REALM.value,
    keycloak_url: Args.keycloak_url = Defaults.KEYCLOAK_URL.value,
    keycloak_admin_user: Args.keycloak_admin_user = Defaults.KEYCLOAK_ADMIN_USER.value,
    ui_client_id: Args.ui_client_id = Defaults.UI_CLIENT_ID.value,
    ui_web_origins: Args.ui_web_origins = Defaults.UI_WEB_ORIGINS.value,
    ui_redirect_uris: Args.ui_redirect_uris = Defaults.UI_REDIRECT_URIS.value,
):
    """Create the User Interfaces client."""

    keycloak_admin = moderatecli.kc.login_admin(
        keycloak_url=keycloak_url,
        keycloak_admin_user=keycloak_admin_user,
        keycloak_admin_pass=keycloak_admin_pass,
        realm_name=moderate_realm,
    )

    moderatecli.kc.create_ui_client(
        keycloak_admin=keycloak_admin,
        client_id=ui_client_id,
        web_origins=ui_web_origins.split(","),
        redirect_uris=ui_redirect_uris.split(","),
    )


@app.command()
def create_api_admin_role(
    keycloak_admin_pass: Args.keycloak_admin_pass,
    apisix_api_admin_role: Args.apisix_api_admin_role = Defaults.APISIX_API_ADMIN_ROLE.value,
    keycloak_url: Args.keycloak_url = Defaults.KEYCLOAK_URL.value,
    keycloak_admin_user: Args.keycloak_admin_user = Defaults.KEYCLOAK_ADMIN_USER.value,
    moderate_realm: Args.moderate_realm = Defaults.MODERATE_REALM.value,
    apisix_client_id: Args.apisix_client_id = Defaults.APISIX_CLIENT_ID.value,
):
    """Create the API Admin role for APISIX."""

    keycloak_admin = moderatecli.kc.login_admin(
        keycloak_url=keycloak_url,
        keycloak_admin_user=keycloak_admin_user,
        keycloak_admin_pass=keycloak_admin_pass,
        realm_name=moderate_realm,
    )

    moderatecli.kc.create_role(
        keycloak_admin=keycloak_admin,
        client_id=apisix_client_id,
        role_name=apisix_api_admin_role,
    )


@app.command()
def create_keycloak_user(
    keycloak_admin_pass: Args.keycloak_admin_pass,
    user_username: Args.user_username,
    user_password: Args.user_password,
    keycloak_url: Args.keycloak_url = Defaults.KEYCLOAK_URL.value,
    keycloak_admin_user: Args.keycloak_admin_user = Defaults.KEYCLOAK_ADMIN_USER.value,
    moderate_realm: Args.moderate_realm = Defaults.MODERATE_REALM.value,
    apisix_client_id: Args.apisix_client_id = Defaults.APISIX_CLIENT_ID.value,
    apisix_api_admin_role: Args.apisix_api_admin_role = Defaults.APISIX_API_ADMIN_ROLE.value,
):
    """Create a new user in the MODERATE realm."""

    keycloak_admin = moderatecli.kc.login_admin(
        keycloak_url=keycloak_url,
        keycloak_admin_user=keycloak_admin_user,
        keycloak_admin_pass=keycloak_admin_pass,
        realm_name=moderate_realm,
    )

    moderatecli.kc.create_user(
        keycloak_admin=keycloak_admin,
        username=user_username,
        password=user_password,
        client_roles={apisix_client_id: [apisix_api_admin_role]},
    )


def main():
    coloredlogs.install(level=os.getenv("LOG_LEVEL", "DEBUG"))
    app()


if __name__ == "__main__":
    main()
