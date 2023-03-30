#!/usr/bin/env bash

set -e
set -x

# Run before to configure kubectl to access the GKE cluster:
# gcloud container clusters get-credentials gke-cluster --region europe-west1-b --project moderate-prod

: ${BASE_DOMAIN:="moderate.cloud"}
: ${NGINX_CONTROLLER_SERVICE:="ingress-nginx-controller"}
: ${PROJECT_ID:="moderate-common"}
: ${MANAGED_ZONE:="moderate-cloud"}
: ${TTL:="300"}

DOMAINS=(
    "docs"
    "yatai"
    "keycloak"
    "api"
    "docs.api"
)

LB_IP=$(kubectl get \
    service/${NGINX_CONTROLLER_SERVICE} \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

gcloud --project=${PROJECT_ID} \
    dns record-sets transaction abort \
    --zone=${MANAGED_ZONE} || true

gcloud --project=${PROJECT_ID} \
    dns record-sets transaction start \
    --zone=${MANAGED_ZONE}

for val in ${DOMAINS[@]}; do
    CURR_DOMAIN="${val}.${BASE_DOMAIN}"

    gcloud --project=${PROJECT_ID} \
        dns record-sets delete ${CURR_DOMAIN} \
        --type=A \
        --zone=${MANAGED_ZONE} || true

    gcloud --project=${PROJECT_ID} \
        dns record-sets transaction add ${LB_IP} \
        --name=${CURR_DOMAIN} \
        --ttl=${TTL} \
        --type=A \
        --zone=${MANAGED_ZONE}
done

gcloud --project=${PROJECT_ID} \
    dns record-sets transaction execute \
    --zone=${MANAGED_ZONE}

gcloud --project=${PROJECT_ID} \
    dns record-sets list \
    --zone=${MANAGED_ZONE}
