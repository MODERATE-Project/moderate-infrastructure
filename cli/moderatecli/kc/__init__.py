import logging
import pprint
import time
from typing import Union

from keycloak import KeycloakAdmin, KeycloakOpenIDConnection

from moderatecli.kc.data import read_data
from moderatecli.utils import dict_deep_merge

_JSON_OPEN_METADATA_CLIENT = "open_metadata_client.json"
_JSON_APISIX_CLIENT = "apisix_client.json"

_logger = logging.getLogger(__name__)


def build_open_metadata_client_data(
    client_id: str, client_secret: str, root_url: str
) -> dict:
    data = read_data(_JSON_OPEN_METADATA_CLIENT)

    return dict_deep_merge(
        data,
        {
            "clientId": client_id,
            "name": f"Open Metadata client ({client_id})",
            "rootUrl": root_url,
            "adminUrl": root_url,
            "secret": client_secret,
            "redirectUris": [f"{root_url}/*"],
            "webOrigins": [root_url],
            "attributes": {
                "client.secret.creation.time": int(time.time()),
            },
        },
    )


def build_apisix_client_data(
    client_id: str,
    client_secret: str,
    moderate_api_resource: str,
    yatai_resource: str,
    resources_type: str,
) -> dict:
    data = read_data(_JSON_APISIX_CLIENT)

    return dict_deep_merge(
        data,
        {
            "clientId": client_id,
            "name": f"APISIX client ({client_id})",
            "secret": client_secret,
            "attributes": {
                "client.secret.creation.time": int(time.time()),
            },
            "authorizationSettings": {
                "resources": [
                    {
                        "name": "Default Resource",
                        "type": resources_type,
                        "ownerManagedAccess": False,
                        "uris": ["/*"],
                    },
                    {
                        "name": yatai_resource,
                        "type": resources_type,
                        "ownerManagedAccess": True,
                        "displayName": "Yatai Inference APIs",
                        "uris": ["/*"],
                    },
                    {
                        "name": moderate_api_resource,
                        "type": resources_type,
                        "ownerManagedAccess": True,
                        "displayName": "MODERATE HTTP API",
                        "uris": ["/*"],
                    },
                ],
                "policies": [
                    {
                        "name": "Default Policy",
                        "description": "A policy that grants access only for users within this realm",
                        "type": "js",
                        "logic": "POSITIVE",
                        "decisionStrategy": "AFFIRMATIVE",
                        "config": {
                            "code": "// by default, grants any permission associated with this policy\n$evaluation.grant();\n"
                        },
                    },
                    {
                        "name": "Default Permission",
                        "description": "A permission that applies to the default resource type",
                        "type": "resource",
                        "logic": "POSITIVE",
                        "decisionStrategy": "UNANIMOUS",
                        "config": {
                            "defaultResourceType": resources_type,
                            "applyPolicies": '["Default Policy"]',
                        },
                    },
                ],
            },
        },
    )


def login_admin(
    keycloak_url: str,
    keycloak_admin_user: str,
    keycloak_admin_pass: str,
    realm_name: Union[str, None] = None,
) -> KeycloakAdmin:
    conn_kwargs = (
        {}
        if not realm_name
        else {"realm_name": realm_name, "user_realm_name": "master"}
    )

    keycloak_connection = KeycloakOpenIDConnection(
        server_url=keycloak_url,
        username=keycloak_admin_user,
        password=keycloak_admin_pass,
        verify=True,
        **conn_kwargs,
    )

    return KeycloakAdmin(connection=keycloak_connection)


def create_moderate_realm(
    keycloak_admin: KeycloakAdmin,
    realm_name: str,
) -> dict:
    _logger.info("Creating realm %s", realm_name)

    keycloak_admin.create_realm(
        {"realm": realm_name, "enabled": True}, skip_exists=True
    )

    data = keycloak_admin.get_realm(realm_name)
    _logger.debug("Realm data:\n%s", pprint.pformat(data))
    return data


def create_client(
    keycloak_admin: KeycloakAdmin,
    client_id: str,
    client_data: dict,
) -> dict:
    _logger.info("Creating client %s", client_id)
    _logger.debug("POSTing client data:\n%s", pprint.pformat(client_data))
    keycloak_admin.create_client(client_data, skip_exists=True)
    client_uuid = keycloak_admin.get_client_id(client_id)
    data = keycloak_admin.get_client(client_uuid)
    _logger.debug("Client data:\n%s", pprint.pformat(data))
    return data


def create_open_metadata_client(
    keycloak_admin: KeycloakAdmin,
    client_id: str,
    client_secret: str,
    root_url: str,
) -> dict:
    client_data = build_open_metadata_client_data(
        client_id=client_id,
        client_secret=client_secret,
        root_url=root_url,
    )

    return create_client(
        keycloak_admin=keycloak_admin,
        client_id=client_id,
        client_data=client_data,
    )


def create_apisix_client(
    keycloak_admin: KeycloakAdmin,
    client_id: str,
    client_secret: str,
    moderate_api_resource: str,
    yatai_resource: str,
    resources_type: str,
) -> dict:
    client_data = build_apisix_client_data(
        client_id=client_id,
        client_secret=client_secret,
        moderate_api_resource=moderate_api_resource,
        yatai_resource=yatai_resource,
        resources_type=resources_type,
    )

    return create_client(
        keycloak_admin=keycloak_admin,
        client_id=client_id,
        client_data=client_data,
    )


def create_user(
    keycloak_admin: KeycloakAdmin,
    username: str,
    password: str,
    email: Union[str, None] = None,
    email_verified: bool = True,
    first_name: Union[str, None] = None,
    last_name: Union[str, None] = None,
) -> dict:
    user_data = {
        "username": username,
        "enabled": True,
        "credentials": [{"type": "password", "value": password, "temporary": False}],
    }

    if email:
        user_data["email"] = email
        user_data["emailVerified"] = email_verified

    if first_name:
        user_data["firstName"] = first_name

    if last_name:
        user_data["lastName"] = last_name

    _logger.info("Creating user: %s", username)
    user_repr = keycloak_admin.create_user(user_data, exist_ok=True)
    _logger.debug("User creation response:\n%s", pprint.pformat(user_repr))

    return user_repr
