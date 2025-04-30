variable "cluster_config" {
  type        = any
  description = "Cluster to install argocd ons"
}

variable "argo_namespace" {
  type        = string
  default     = "argocd"
  description = "namespace to deploy argo to"
}

variable "project_id" {
  type        = string
  description = "The project id"
}

variable "argo_helm_chart_version" {
  type        = string
  description = "Version of the argocd helm chart to use"
  default     = "6.8.1"
}

variable "external_secrets_namespace" {
  type        = string
  default     = "external-secrets"
  description = "namespace to deploy external secrets to"
}

variable "external_secrets_helm_chart_version" {
  type        = string
  default     = "0.9.17"
  description = "version of external secrets helm chart to use"
}

variable "dns_zone" {
  type        = any
  description = "dns zone to use"
}

variable "existing_secrets" {
  type        = list(string)
  description = "A list of existing secrets argocd will need access to"
  default     = []

}