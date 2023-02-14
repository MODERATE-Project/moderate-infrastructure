terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.53.0"
    }
  }
}

terraform {
  cloud {
    organization = "moderate"

    workspaces {
      name = "common-gcp"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "artifact_registry" {
  source     = "../modules/artifact_registry"
  project_id = var.project_id
  region     = var.region
}
