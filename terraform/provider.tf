terraform {
  backend "gcs" {
    bucket  = "gke-remote-tf"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.16.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.29.0, < 3.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.15.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region = var.region
}

provider "helm" {
  alias = "gke"
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = local.cluster_ca_certificate
    token                  = local.cluster_token
  }
}

provider "kubernetes" {
  alias = "gke"
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.cluster_token
}