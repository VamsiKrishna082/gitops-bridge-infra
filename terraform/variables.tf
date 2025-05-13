

variable "project_id" {
    description = "The GCP Project ID"
    type        = string
    default = "vamsi-krishna-sandbox"
}

variable "labels" {
  description = "A map of labels to apply to contained resources."
  default     = {}
  type        = map(string)
}

variable "region" {
  description = "GCP region to deploy resources to."
  default     = "us-central1"
}

variable "google_oauth_client_id" {
    description = "Google Oauth id"
}

variable "google_oauth_client_secret" {
  description = "Google Oauth secret"
}

variable "backstage_auth_secret" {
  description = "backstage backend secret"
}

variable "backstage_db_password" {
    description = "backstage user db password"
}

variable "backstage_github_key" {
  description = "PAT For sample testing"
}

variable "cloud_sql_ip" {
    description = "ip address of postgress db instance"
}

variable "github_client_id" {
    description = "github client id"
}

variable "github_client_secret" {
    description = "github client secret"
}

variable "argocd_host_name" {
    description = "argocd host name"
}

variable "grafana_host_name" {
    description = "grafana host name"
}

variable "argocd_token" {
    description = "argocd auth token"
}

variable "grafana_token" {
    description = "grafana auth token"
}

variable "techdocs_gcs_bucket" {
    description = "techdocs gcs bucket"
}

variable "backstage_host_name" {
    description = "backstage host name"
}



variable "postgres" {
  description = "Configuration for Postgres"
  type = object({
    version = string
    tier    = string
  })
  default = {
    version = "POSTGRES_15"
    tier    = "db-f1-micro"
  }
}


variable "addons" {
  description = "Kubernetes addons"
  type        = any
  default = {
    enable_argocd           = true
    enable_cert_manager     = true
    enable_external_dns     = true
    enable_external_secrets = false
    enable_ingress_nginx    = false
    enable_keycloak         = false
    enable_argo_rollouts    = false
    enable_goldilocks       = false
    enable_snorlax          = false
    enable_keda             = false
  }
}

variable "gitops_config" {
  description = "Github configration for the Gitops repository holding manifests/charts."
  type        = map(map(string))
  default = {
    addons = {
      org      = "https://github.com/tensure"
      repo     = "gitops-apps-config"
      revision = "main"
      basepath = ""
      path     = "bootstrap/control-plane/addons"
    }
    workloads = {
      org      = "https://github.com/tensure"
      repo     = "gitops-apps-config"
      revision = "main"
      basepath = ""
      path     = "bootstrap/workloads"
    }
  }
}