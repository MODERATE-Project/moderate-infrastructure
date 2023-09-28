import logging
import pprint
import time
from dataclasses import dataclass
from typing import List

import requests

_APISIX_RESOURCES_DEFAULT_TYPE = "urn:apisix:resources:default"
_REQUESTS_TIMEOUT = 90

_logger = logging.getLogger(__name__)


@dataclass
class Config:
    keycloak_url: str
    keycloak_admin_user: str
    keycloak_admin_pass: str
    moderate_realm: str
    apisix_client_id: str
    apisix_client_secret: str
    apisix_client_resource_yatai: str
    apisix_client_resource_moderate_api: str
    open_metadata_client_id: str
    open_metadata_client_secret: str
    open_metadata_root_url: str


def build_open_metadata_client_props(
    client_id: str, client_secret: str, root_url: str, name: str = "Open Metadata"
) -> dict:
    return {
        "clientId": client_id,
        "name": name,
        "description": "",
        "rootUrl": root_url,
        "adminUrl": root_url,
        "baseUrl": "",
        "surrogateAuthRequired": False,
        "enabled": True,
        "alwaysDisplayInConsole": False,
        "clientAuthenticatorType": "client-secret",
        "secret": client_secret,
        "redirectUris": [f"{root_url}/*"],
        "webOrigins": [root_url],
        "notBefore": 0,
        "bearerOnly": False,
        "consentRequired": False,
        "standardFlowEnabled": True,
        "implicitFlowEnabled": True,
        "directAccessGrantsEnabled": True,
        "serviceAccountsEnabled": True,
        "publicClient": False,
        "frontchannelLogout": True,
        "protocol": "openid-connect",
        "attributes": {
            "oidc.ciba.grant.enabled": False,
            "oauth2.device.authorization.grant.enabled": False,
            "client.secret.creation.time": int(time.time()),
            "backchannel.logout.session.required": True,
            "backchannel.logout.revoke.offline.tokens": False,
        },
        "authenticationFlowBindingOverrides": {},
        "fullScopeAllowed": True,
        "nodeReRegistrationTimeout": -1,
        "protocolMappers": [
            {
                "name": "Client ID",
                "protocol": "openid-connect",
                "protocolMapper": "oidc-usersessionmodel-note-mapper",
                "consentRequired": False,
                "config": {
                    "user.session.note": "client_id",
                    "id.token.claim": True,
                    "access.token.claim": True,
                    "claim.name": "client_id",
                    "jsonType.label": "String",
                },
            },
            {
                "name": "Client IP Address",
                "protocol": "openid-connect",
                "protocolMapper": "oidc-usersessionmodel-note-mapper",
                "consentRequired": False,
                "config": {
                    "user.session.note": "clientAddress",
                    "id.token.claim": True,
                    "access.token.claim": True,
                    "claim.name": "clientAddress",
                    "jsonType.label": "String",
                },
            },
            {
                "name": "Client Host",
                "protocol": "openid-connect",
                "protocolMapper": "oidc-usersessionmodel-note-mapper",
                "consentRequired": False,
                "config": {
                    "user.session.note": "clientHost",
                    "id.token.claim": True,
                    "access.token.claim": True,
                    "claim.name": "clientHost",
                    "jsonType.label": "String",
                },
            },
        ],
        "defaultClientScopes": ["web-origins", "acr", "roles", "profile", "email"],
        "optionalClientScopes": [
            "address",
            "phone",
            "offline_access",
            "microprofile-jwt",
        ],
        "access": {"view": True, "configure": True, "manage": True},
    }


def build_apisix_client_props(config: Config) -> dict:
    return {
        "name": "APISIX Gateway",
        "publicClient": False,
        "serviceAccountsEnabled": True,
        "standardFlowEnabled": True,
        "directAccessGrantsEnabled": True,
        "implicitFlowEnabled": False,
        "fullScopeAllowed": True,
        "alwaysDisplayInConsole": True,
        "authorizationServicesEnabled": True,
        "authorizationSettings": {
            "allowRemoteResourceManagement": True,
            "policyEnforcementMode": "ENFORCING",
            "resources": [
                {
                    "name": "Default Resource",
                    "type": _APISIX_RESOURCES_DEFAULT_TYPE,
                    "ownerManagedAccess": False,
                    "uris": ["/*"],
                },
                {
                    "name": config.apisix_client_resource_yatai,
                    "type": _APISIX_RESOURCES_DEFAULT_TYPE,
                    "ownerManagedAccess": True,
                    "displayName": "Yatai Inference APIs",
                    "uris": ["/*"],
                },
                {
                    "name": config.apisix_client_resource_moderate_api,
                    "type": _APISIX_RESOURCES_DEFAULT_TYPE,
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
                        "defaultResourceType": _APISIX_RESOURCES_DEFAULT_TYPE,
                        "applyPolicies": '["Default Policy"]',
                    },
                },
            ],
            "scopes": [],
            "decisionStrategy": "UNANIMOUS",
        },
    }


def join_url_parts(*args: List[str]) -> str:
    return "/".join(map(lambda x: str(x).rstrip("/"), args))


def build_headers(admin_token: str) -> dict:
    return {
        "Authorization": f"Bearer {admin_token}",
        "Content-Type": "application/json",
    }


def get_admin_token(config: Config) -> str:
    token_url = join_url_parts(
        config.keycloak_url, "realms/master/protocol/openid-connect/token"
    )

    token_data = {
        "grant_type": "password",
        "client_id": "admin-cli",
        "username": config.keycloak_admin_user,
        "password": config.keycloak_admin_pass,
    }

    response = requests.post(token_url, data=token_data, timeout=_REQUESTS_TIMEOUT)
    access_token = response.json()["access_token"]

    return access_token


def get_realm(config: Config, admin_token: str, realm_name: str) -> dict:
    headers = build_headers(admin_token)
    url = join_url_parts(config.keycloak_url, "admin/realms", realm_name)
    response = requests.get(url, headers=headers, timeout=_REQUESTS_TIMEOUT)
    response.raise_for_status()

    return response.json()


def create_realm(config: Config, admin_token: str, realm_name: str) -> dict:
    headers = build_headers(admin_token)

    realm_data = {
        "realm": realm_name,
        "enabled": True,
        "sslRequired": "external",
        "userManagedAccessAllowed": True,
    }

    url = join_url_parts(config.keycloak_url, "admin/realms")

    response = requests.post(
        url, json=realm_data, headers=headers, timeout=_REQUESTS_TIMEOUT
    )

    response.raise_for_status()

    return get_realm(config=config, admin_token=admin_token, realm_name=realm_name)


def get_client(
    config: Config, realm_name: str, admin_token: str, client_id: str
) -> dict:
    headers = build_headers(admin_token)
    url = join_url_parts(config.keycloak_url, "admin/realms", realm_name, "clients")
    response = requests.get(url, headers=headers, timeout=_REQUESTS_TIMEOUT)
    response.raise_for_status()
    clients = response.json()
    _logger.debug("Found clients:\n%s", pprint.pformat(clients))

    return next(item for item in clients if item["clientId"] == client_id)


def create_client(
    config: Config,
    realm_name: str,
    admin_token: str,
    client_id: str,
    client_props: dict,
) -> dict:
    headers = build_headers(admin_token)

    client_data = {
        "clientId": client_id,
        "name": client_id,
        "enabled": True,
        "protocol": "openid-connect",
        **client_props,
    }

    _logger.debug("POSTing client data:\n%s", pprint.pformat(client_data))

    url = join_url_parts(config.keycloak_url, "admin/realms", realm_name, "clients")

    response = requests.post(
        url, json=client_data, headers=headers, timeout=_REQUESTS_TIMEOUT
    )

    response.raise_for_status()

    get_client_kwargs = {
        "config": config,
        "realm_name": realm_name,
        "admin_token": admin_token,
        "client_id": client_id,
    }

    return get_client(**get_client_kwargs)


def create_moderate_realm(config: Config, admin_token: str):
    try:
        _logger.info("Checking if realm %s exists", config.moderate_realm)

        return get_realm(
            config=config, admin_token=admin_token, realm_name=config.moderate_realm
        )
    except Exception:
        _logger.info("Realm %s does not exist, creating...", config.moderate_realm)

        return create_realm(
            config=config, admin_token=admin_token, realm_name=config.moderate_realm
        )


def _create_client(
    client_id: str, client_props: dict, config: Config, admin_token: str
) -> dict:
    try:
        _logger.info("Checking if client %s exists", client_id)

        return get_client(
            config=config,
            realm_name=config.moderate_realm,
            admin_token=admin_token,
            client_id=client_id,
        )
    except Exception:
        _logger.info("Client %s does not exist, creating...", client_id)

        return create_client(
            config=config,
            realm_name=config.moderate_realm,
            admin_token=admin_token,
            client_id=client_id,
            client_props=client_props,
        )


def create_apisix_client(config: Config, admin_token: str) -> dict:
    client_props = {
        **build_apisix_client_props(config=config),
        **{"secret": config.apisix_client_secret},
    }

    return _create_client(
        client_id=config.apisix_client_id,
        client_props=client_props,
        config=config,
        admin_token=admin_token,
    )


def create_open_metadata_client(config: Config, admin_token: str) -> dict:
    client_props = build_open_metadata_client_props(
        client_id=config.open_metadata_client_id,
        client_secret=config.open_metadata_client_secret,
        root_url=config.open_metadata_root_url,
    )

    return _create_client(
        client_id=config.open_metadata_client_id,
        client_props=client_props,
        config=config,
        admin_token=admin_token,
    )


def create_keycloak_entities(
    keycloak_url: str,
    keycloak_admin_user: str,
    keycloak_admin_pass: str,
    moderate_realm: str,
    apisix_client_id: str,
    apisix_client_secret: str,
    apisix_client_resource_yatai: str,
    apisix_client_resource_moderate_api: str,
    open_metadata_client_id: str,
    open_metadata_client_secret: str,
    open_metadata_root_url: str,
):
    """Create Keycloak entities."""

    _logger.info("Initializing Keycloak entities")

    config = Config(
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

    admin_token = get_admin_token(config=config)

    moderate_realm = create_moderate_realm(config=config, admin_token=admin_token)
    _logger.debug("MODERATE realm:\n%s", pprint.pformat(moderate_realm))

    apisix_client = create_apisix_client(config=config, admin_token=admin_token)
    _logger.debug("APISIX client:\n%s", pprint.pformat(apisix_client))

    om_client = create_open_metadata_client(config=config, admin_token=admin_token)
    _logger.debug("Open Metadata client:\n%s", pprint.pformat(om_client))
