import logging
import pprint
from typing import Union

from keycloak import KeycloakAdmin, KeycloakPostError

from moderatecli.utils import slugify, snake_case

_logger = logging.getLogger(__name__)

_BROWSER_FLOW = "browser"


def get_client_access_role_name(client_id: str) -> str:
    return snake_case(slugify(client_id)) + "_access_role"


def get_role_based_flow_name(role_name: str) -> str:
    return "role_based_flow_{}".format(role_name)


def create_role_for_client_access(
    keycloak_admin: KeycloakAdmin,
    client_id: str,
) -> str:
    role_name = get_client_access_role_name(client_id=client_id)

    role_repr = {
        "name": role_name,
        "description": "Access role for client {}".format(client_id),
        "composite": False,
        "clientRole": False,
    }

    _logger.info("Creating realm role '%s' if not exists", role_name)
    return keycloak_admin.create_realm_role(role_repr, skip_exists=True)


def create_role_based_browser_flow_draft(
    keycloak_admin: KeycloakAdmin,
    role_name: str,
    bind_to_client_id: Union[str, None] = None,
) -> dict:
    """
    Initialize a copy of the browser authentication flow to restrict access to the given role.
    This should ideally fully configure the flow,
    but for now it just copies it due to the complexity of the Keycloak API interactions.
    """

    flow_alias = get_role_based_flow_name(role_name=role_name)
    payload = {"newName": flow_alias}

    try:
        _logger.info("Copying flow '%s' to '%s'", _BROWSER_FLOW, flow_alias)
        keycloak_admin.copy_authentication_flow(payload, flow_alias=_BROWSER_FLOW)
    except KeycloakPostError as ex:
        _logger.info("Flow '%s' already exists", flow_alias)
        _logger.debug("%s: %s", ex.__class__, ex)
        return

    flow = next(
        item
        for item in keycloak_admin.get_authentication_flows()
        if item.get("alias") == flow_alias
    )

    _logger.debug(
        "Retrieved new flow '%s' from Keycloak:\n%s",
        flow_alias,
        pprint.pformat(flow),
    )

    _logger.warning(
        "Please note that the flow is not fully configured yet! There are still some manual steps to do."
    )

    if not bind_to_client_id:
        _logger.info("No client ID provided, not binding flow to client")
        return

    client_uuid = keycloak_admin.get_client_id(client_id=bind_to_client_id)

    _logger.info(
        "Binding flow '%s' (%s) to client '%s'",
        flow["alias"],
        flow["id"],
        bind_to_client_id,
    )

    keycloak_admin.update_client(
        client_id=client_uuid,
        payload={"authenticationFlowBindingOverrides": {"browser": flow["id"]}},
    )

    return flow
