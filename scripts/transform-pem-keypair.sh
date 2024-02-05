#!/bin/sh

set -e

(apt-get update -y && apt-get install -y curl || true) 2>/dev/null
eval "$(curl -Ssf https://pkgx.sh)"

set -ux

ls -lah ${INPUT_KEYS_DIR}
input_pem_privkey="${INPUT_KEYS_DIR}/${NAME_PRIV_KEY}.pem"

if [ ! -f "${input_pem_privkey}" ]; then
    echo "Error: ${input_pem_privkey} does not exist"
    exit 1
fi

mkdir -p ${OUTPUT_KEYS_DIR}
ls -lah ${OUTPUT_KEYS_DIR}

pkgx openssl@3.1 pkcs8 \
    -topk8 \
    -inform PEM \
    -outform DER \
    -in ${input_pem_privkey} \
    -out ${OUTPUT_KEYS_DIR}/${NAME_PRIV_KEY}.der \
    -nocrypt

pkgx openssl@3.1 rsa \
    -in ${input_pem_privkey} \
    -pubout \
    -outform DER \
    -out ${OUTPUT_KEYS_DIR}/${NAME_PUB_KEY}.der

chmod -R 777 -v ${OUTPUT_KEYS_DIR}
