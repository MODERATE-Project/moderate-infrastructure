output "repository_id" {
  value = google_artifact_registry_repository.image_repository.id
}

output "repository_name" {
  value = google_artifact_registry_repository.image_repository.name
}

output "repository_location" {
  value = google_artifact_registry_repository.image_repository.location
}
