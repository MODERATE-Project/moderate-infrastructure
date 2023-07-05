# Install package requirements

import subprocess
import sys

_REQUIREMENTS = ["coloredlogs==15.0.1", "requests==2.31.0"]


def install(package):
    print("Installing", package)
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-U", package])


for package in _REQUIREMENTS:
    install(package)

# Create the Keycloak entities if necessary (e.g. realms, clients)

import collections
import logging
import os
import pprint
import sys
from typing import List

import coloredlogs
import requests

_logger = logging.getLogger(__name__)

_APISIX_RESOURCES_DEFAULT_TYPE = "urn:apisix:resources:default"

_VARIABLES = [
    ("KEYCLOAK_URL", "https://keycloak.moderate.cloud", str),
    ("KEYCLOAK_ADMIN_USER", "admin", str),
    ("KEYCLOAK_ADMIN_PASS", None, str),
    ("MODERATE_REALM", "moderate", str),
    ("APISIX_CLIENT_ID", "apisix", str),
    ("APISIX_CLIENT_SECRET", None, str),
    ("APISIX_CLIENT_RESOURCE_YATAI", "yatai", str),
    ("APISIX_CLIENT_RESOURCE_MODERATE_API", "moderateapi", str),
]

Config = collections.namedtuple("Config", [item.lower() for item, _, _ in _VARIABLES])


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


def get_config() -> Config:
    config_kwargs = {
        key.lower(): converter(os.getenv(key, default))
        if converter
        else os.getenv(key, default)
        for key, default, converter in _VARIABLES
    }

    return Config(**config_kwargs)


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

    response = requests.post(token_url, data=token_data)
    access_token = response.json()["access_token"]

    return access_token


def get_realm(config: Config, admin_token: str, realm_name: str) -> dict:
    headers = build_headers(admin_token)
    url = join_url_parts(config.keycloak_url, "admin/realms", realm_name)
    response = requests.get(url, headers=headers)
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
    response = requests.post(url, json=realm_data, headers=headers)
    response.raise_for_status()

    return get_realm(config=config, admin_token=admin_token, realm_name=realm_name)


def get_client(
    config: Config, realm_name: str, admin_token: str, client_id: str
) -> dict:
    headers = build_headers(admin_token)
    url = join_url_parts(config.keycloak_url, "admin/realms", realm_name, "clients")
    response = requests.get(url, headers=headers)
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
    response = requests.post(url, json=client_data, headers=headers)
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
    except:
        _logger.info("Realm %s does not exist, creating...", config.moderate_realm)

        return create_realm(
            config=config, admin_token=admin_token, realm_name=config.moderate_realm
        )


def create_apisix_client(config: Config, admin_token: str):
    try:
        _logger.info("Checking if client %s exists", config.apisix_client_id)

        return get_client(
            config=config,
            realm_name=config.moderate_realm,
            admin_token=admin_token,
            client_id=config.apisix_client_id,
        )
    except:
        _logger.info("Client %s does not exist, creating...", config.apisix_client_id)

        apisix_client_props = {
            **build_apisix_client_props(config=config),
            **{"secret": config.apisix_client_secret},
        }

        return create_client(
            config=config,
            realm_name=config.moderate_realm,
            admin_token=admin_token,
            client_id=config.apisix_client_id,
            client_props=apisix_client_props,
        )


def main():
    _logger.info("Initializing Keycloak entities")
    config = get_config()
    admin_token = get_admin_token(config=config)

    moderate_realm = create_moderate_realm(config=config, admin_token=admin_token)
    _logger.debug("MODERATE realm:\n%s", pprint.pformat(moderate_realm))

    apisix_client = create_apisix_client(config=config, admin_token=admin_token)
    _logger.debug("APISIX client:\n%s", pprint.pformat(apisix_client))


if __name__ == "__main__":
    coloredlogs.install(level=os.getenv("LOG_LEVEL", "INFO"))

    try:
        main()
    except:
        _logger.error("Critical error", exc_info=True)
        sys.exit(1)
