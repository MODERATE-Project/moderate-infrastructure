#!/usr/bin/env bash
# Initializes .env and secrets/ if missing; appends new variables;
# never overwrites existing values or keys.

set -euo pipefail

# The exit trap needs this path after the function that creates it returns.
temporary_env_file=''

remove_temporary_environment_file() {
    rm -f "$temporary_env_file"
}

write_environment_line() {
    local line=$1
    local generated_value

    # Generate values only for empty variables with a recognized suffix.
    case "$line" in
    \#*)
        printf '%s\n' "$line"
        ;;
    *_PASSWORD= | *_SECRET=)
        generated_value=$(openssl rand -hex 32)
        printf '%s%s\n' "$line" "$generated_value"
        ;;
    *_FERNET_KEY=)
        generated_value=$(openssl rand -base64 32 | tr '+/' '-_')
        printf '%s%s\n' "$line" "$generated_value"
        ;;
    *)
        printf '%s\n' "$line"
        ;;
    esac
}

update_environment_file() {
    local line variable_name

    if [[ ! -f .env ]]; then
        cp .env.example .env
    fi

    temporary_env_file=$(mktemp .env.XXXXXX)
    trap remove_temporary_environment_file EXIT

    {
        while IFS= read -r line || [[ -n $line ]]; do
            write_environment_line "$line"
        done <.env

        # Check the original .env so existing entries keep their values and order.
        while IFS= read -r line || [[ -n $line ]]; do
            if [[ $line =~ ^[A-Za-z0-9_]+= ]]; then
                variable_name=${line%%=*}
                if ! grep -q "^${variable_name}=" .env; then
                    write_environment_line "$line"
                fi
            fi
        done <.env.example
    } >"$temporary_env_file"

    mv "$temporary_env_file" .env
}

ensure_jwt_keypair() {
    local private_key=secrets/openmetadata_jwt_private.der
    local public_key=secrets/openmetadata_jwt_public.der

    # OpenMetadata reads the private key as PKCS#8 DER and the public key as X.509 DER.
    mkdir -p secrets
    if [[ ! -f $private_key ]]; then
        openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform DER -out "$private_key"
        # A public key left from an older private key would no longer match.
        rm -f "$public_key"
    fi
    if [[ ! -f $public_key ]]; then
        openssl pkey -inform DER -in "$private_key" -pubout -outform DER -out "$public_key"
    fi
}

main() {
    cd "$(dirname "$0")/.."
    umask 077

    update_environment_file
    ensure_jwt_keypair
}

main "$@"
