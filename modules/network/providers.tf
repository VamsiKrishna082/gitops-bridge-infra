# ------------------------ #
# Prooviders Configuration #
# ------------------------ #

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.16.0"
    }
  }
}

provider "google" {
  project = var.gcp.project_id
  region  = var.gcp.region
}
