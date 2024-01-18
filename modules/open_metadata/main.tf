resource "kubernetes_namespace" "open_metadata" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "openmetadata" }
    name        = "openmetadata"
  }
}

locals {
  namespace = var.namespace == null ? one(kubernetes_namespace.open_metadata[*].id) : var.namespace
}

resource "random_password" "password_open_metadata_sql_user" {
  length  = 20
  special = false
}

resource "google_sql_user" "open_metadata_sql_user" {
  instance        = var.cloud_sql_instance_name
  name            = "openmetadata"
  password        = random_password.password_open_metadata_sql_user.result
  deletion_policy = "ABANDON"
}

resource "google_sql_database" "sql_database_open_metadata" {
  instance = var.cloud_sql_instance_name
  name     = "openmetadata"
}

locals {
  // trunk-ignore(checkov/CKV_SECRET_6)
  open_metadata_postgres_password_key = "openmetadata-postgres-password"
  keycloak_url                        = trim(var.keycloak_url, "/")
  open_metadata_url                   = "https://${var.open_metadata_domain}"
  open_metadata_privkey               = "open_metadata_privkey"
  open_metadata_pubkey                = "open_metadata_pubkey"
  elasticsearch_host                  = "${kubernetes_service.elastic.metadata[0].name}.${local.namespace}.svc.cluster.local"
  elasticsearch_port                  = local.elastic_port_http
  volume_jwt_init_script              = "openmetadata-jwt-init-script-vol"
  volume_jwt_keys                     = "openmetadata-jwt-vol"
  volume_jwt_keys_rw                  = "openmetadata-jwt-vol-rw"
  mount_path_jwt_keys                 = "/etc/openmetadata/jwtkeys"
  jwt_init_script                     = "transform-pem-keypair.sh"
  open_metadata_full_name             = "openmetadata"
  open_metadata_port                  = 8585
  open_metadata_admin_port            = 8586
}

resource "kubernetes_secret" "open_metadata_postgres_secrets" {
  metadata {
    name      = "openmetadata-postgres-secrets"
    namespace = local.namespace
  }

  data = {
    "${local.open_metadata_postgres_password_key}" = google_sql_user.open_metadata_sql_user.password
  }
}

resource "tls_private_key" "open_metadata_jwt_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "kubernetes_secret" "open_metadata_jwt_keys" {
  metadata {
    name      = "openmetadata-jwt-keys"
    namespace = local.namespace
  }

  data = {
    "${local.open_metadata_privkey}.pem" = tls_private_key.open_metadata_jwt_key.private_key_pem
    "${local.open_metadata_pubkey}.pem"  = tls_private_key.open_metadata_jwt_key.public_key_pem
  }
}

resource "kubernetes_config_map" "open_metadata_jwt_init_script" {
  metadata {
    name      = "openmetadata-jwt-init-script"
    namespace = local.namespace
  }

  data = {
    "${local.jwt_init_script}" = file("${path.module}/../../scripts/${local.jwt_init_script}")
  }
}

resource "random_uuid" "open_metadata_jwt_key_id" {}

locals {
  open_metadata_config = {
    fullnameOverride = local.open_metadata_full_name
    ingress = {
      enabled   = var.ingress_enabled
      className = "nginx"
      annotations = {
        "cert-manager.io/cluster-issuer" = var.cert_manager_issuer
      }
      hosts = [{
        host = var.open_metadata_domain
        paths = [{
          path     = "/"
          pathType = "Prefix"
        }]
      }]
      tls = [{
        secretName = "open-metadata-ingress-tls-secret"
        hosts      = [var.open_metadata_domain]
      }]
    }
    openmetadata = {
      config = {
        logLevel = var.open_metadata_log_level
        openmetadata = {
          host      = local.open_metadata_full_name
          uri       = "https://${local.open_metadata_full_name}:${local.open_metadata_port}"
          port      = local.open_metadata_port
          adminPort = local.open_metadata_admin_port
        }
        elasticsearch = {
          host       = local.elasticsearch_host
          searchType = "elasticsearch"
          port       = local.elasticsearch_port
          scheme     = "http"
          trustStore = {
            enabled = false
          }
          auth = {
            enabled = false
          }
        }
        database = {
          host         = var.postgres_host
          port         = var.postgres_port
          driverClass  = "org.postgresql.Driver"
          dbScheme     = "postgresql"
          databaseName = google_sql_database.sql_database_open_metadata.name
          auth = {
            username = google_sql_user.open_metadata_sql_user.name
            password = {
              secretRef = kubernetes_secret.open_metadata_postgres_secrets.metadata[0].name
              secretKey = local.open_metadata_postgres_password_key
            }
          }
          dbParams = "sslmode=disable"
        }
        pipelineServiceClientConfig = {
          enabled = false
        }
        authentication = {
          provider = "custom-oidc"
          publicKeys = [
            "${local.open_metadata_url}/api/v1/system/config/jwks",
            "${local.keycloak_url}/realms/${var.keycloak_realm}/protocol/openid-connect/certs"
          ]
          authority        = "${local.keycloak_url}/realms/${var.keycloak_realm}"
          clientId         = var.open_metadata_keycloak_client_id
          callbackUrl      = "${local.open_metadata_url}/callback"
          enableSelfSignup = false
        }
        authorizer = {
          className              = "org.openmetadata.service.security.DefaultAuthorizer"
          containerRequestFilter = "org.openmetadata.service.security.JwtFilter"
          initialAdmins          = var.initial_admin_usernames
          principalDomain        = var.authorizer_principal_domain
        }
        jwtTokenConfiguration = {
          enabled               = true
          rsapublicKeyFilePath  = "${local.mount_path_jwt_keys}/${local.open_metadata_pubkey}.der"
          rsaprivateKeyFilePath = "${local.mount_path_jwt_keys}/${local.open_metadata_privkey}.der"
          jwtissuer             = "${local.keycloak_url}/realms/${var.keycloak_realm}"
          keyId                 = random_uuid.open_metadata_jwt_key_id.result
        }
      }
    }
    extraVolumes = [
      {
        name = local.volume_jwt_keys
        secret = {
          secretName = kubernetes_secret.open_metadata_jwt_keys.metadata[0].name
        }
      },
      {
        name = local.volume_jwt_init_script
        configMap = {
          name = kubernetes_config_map.open_metadata_jwt_init_script.metadata[0].name
        }
      },
      {
        name     = local.volume_jwt_keys_rw
        emptyDir = {}
      }
    ]
    extraVolumeMounts = [
      {
        name      = local.volume_jwt_keys
        mountPath = "/opt/jwtkeys-readonly"
      },
      {
        name      = local.volume_jwt_init_script
        mountPath = "/opt/scripts"
      },
      {
        name      = local.volume_jwt_keys_rw
        mountPath = local.mount_path_jwt_keys
      }
    ]
    extraInitContainers = [{
      name    = "init-keypair"
      image   = "debian:bookworm"
      command = ["sh", "/opt/scripts/${local.jwt_init_script}"]
      env = [
        {
          name  = "INPUT_KEYS_DIR"
          value = "/opt/jwtkeys-readonly"
        },
        {
          name  = "OUTPUT_KEYS_DIR"
          value = local.mount_path_jwt_keys
        },
        {
          name  = "NAME_PRIV_KEY"
          value = local.open_metadata_privkey
        },
        {
          name  = "NAME_PUB_KEY"
          value = local.open_metadata_pubkey
        }
      ]
      volumeMounts = [
        {
          name      = local.volume_jwt_keys
          mountPath = "/opt/jwtkeys-readonly"
        },
        {
          name      = local.volume_jwt_init_script
          mountPath = "/opt/scripts"
        },
        {
          name      = local.volume_jwt_keys_rw
          mountPath = local.mount_path_jwt_keys
        }
      ]
    }]
  }
}

resource "helm_release" "open_metadata" {
  name       = "openmetadata"
  repository = "https://helm.open-metadata.org/"
  chart      = "openmetadata"
  version    = var.open_metadata_chart_version
  namespace  = local.namespace
  values     = [yamlencode(local.open_metadata_config)]
}
