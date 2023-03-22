output "cluster_issuer_staging_name" {
  value = local.issuer_staging
}

output "cluster_issuer_staging_secret_name" {
  value = local.issuer_secret_staging
}

output "cluster_issuer_prod_name" {
  value = local.issuer_prod
}

output "cluster_issuer_prod_secret_name" {
  value = local.issuer_secret_prod
}

output "cluster_issuer_staging_uid" {
  value = kubectl_manifest.letsencrypt_staging_issuer.live_uid
}

output "cluster_issuer_prod_uid" {
  value = kubectl_manifest.letsencrypt_prod_issuer.live_uid
}
