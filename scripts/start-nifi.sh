#!/usr/bin/env bash
set -euo pipefail

source /opt/nifi/scripts/common.sh

prop_replace nifi.security.keystore ''
prop_replace nifi.security.keystorePasswd ''
prop_replace nifi.security.keyPasswd ''
prop_replace nifi.security.keystoreType PEM
prop_replace nifi.security.keystore.certificate /etc/nifi-tls/nifi.crt
prop_replace nifi.security.keystore.privateKey /etc/nifi-tls/nifi.key
prop_replace nifi.security.truststore ''
prop_replace nifi.security.truststorePasswd ''
prop_replace nifi.security.truststoreType PEM
prop_replace nifi.security.truststore.certificate /etc/nifi-tls/nifi.crt
prop_replace nifi.python.max.processes 4
prop_replace nifi.python.max.processes.per.extension.type 1
prop_replace nifi.python.working.directory ./state/python

exec /opt/nifi/scripts/start.sh
