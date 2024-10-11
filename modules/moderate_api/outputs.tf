output "api_service_host_port" {
  value = "${local.service_name}.${local.namespace}.svc.cluster.local:${local.api_port}"
}

output "api_s3_access_key" {
  value = google_storage_hmac_key.api_bucket_hmac_key.access_id
}

output "api_s3_secret_key" {
  value = google_storage_hmac_key.api_bucket_hmac_key.secret
}

output "api_s3_bucket_name" {
  value = module.bucket.buckets_map[local.api_bucket_name].name
}

output "outputs_s3_bucket_name" {
  value = module.bucket.buckets_map[local.outputs_bucket_name].name
}

output "api_s3_endpoint_url" {
  value = local.s3_endpoint_url
}

output "api_s3_region" {
  value = local.s3_region
}
