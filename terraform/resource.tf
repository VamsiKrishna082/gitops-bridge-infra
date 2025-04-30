resource "google_service_account" "cluster_sa" {
  account_id                   = local.cluster_name
  display_name                 = "Service Account for cert-manager GKE cluster"
  create_ignore_already_exists = true
  project                      = var.project_id
}

resource "google_project_iam_binding" "cluster_sa_roles" {
  for_each = local.cluster_sa_roles
  project  = var.project_id
  role     = each.key
  members = [
    "serviceAccount:${google_service_account.cluster_sa.email}"
  ]
}

#########################
# GKE Cluster Resources #
#########################
resource "google_container_cluster" "cluster" {
  name                = local.cluster_name
  project             = var.project_id
  location            = var.region
  enable_autopilot    = true
  deletion_protection = false
  min_master_version  = local.gke_k8s_version
  node_locations      = ["${var.region}-c"]
  networking_mode     = "VPC_NATIVE"
  network             = local.vpc
  subnetwork          = local.subnet
  resource_labels     = local.labels
  release_channel {
    channel = "RAPID"
  }
  cost_management_config {
    enabled = true
  }
  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.cluster_sa.email
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
    }
  }
}

# module "workload_identity" {
#   source               = "../modules/workload_id_setup"
#   create_k8s_resources = false
#   project_id           = var.project_id
#   service_account_map  = local.workload_identity_service_accounts
# }

# ArgoCD Specific workload identity bootstrapping.
# Instead of there being just one service account in the k8s deployment there are many so our current module won't work.
resource "google_service_account" "argocd" {
  account_id   = "argocd-fleet"
  display_name = "ArgoCD Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "argocd" {
  for_each = toset(["roles/container.admin", "roles/container.developer", "roles/container.viewer", "roles/iam.serviceAccountTokenCreator", "roles/artifactregistry.reader"])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.argocd.email}"
}

resource "google_service_account_iam_binding" "argo_server_workload_identity" {
  service_account_id = google_service_account.argocd.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-server]",
    "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-application-controller]",
    "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-applicationset-controller]",
    "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-repo-server]"
  ]
}

data "google_client_config" "provider" {}

locals {
  cluster_endpoint       = "https://${google_container_cluster.cluster.endpoint}"
  cluster_ca_certificate = google_container_cluster.cluster.master_auth != null ? base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate) : ""
  cluster_token          = data.google_client_config.provider.access_token
}

resource "helm_release" "argocd" {
  provider = helm.gke 

  name             = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  chart            = "argo-cd"
  version          = "7.8.2"
  repository       = "https://argoproj.github.io/argo-helm"

  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value = "$2a$10$h9Eb./X68WocvlfDJBRh.uC3bo0AozLR4aO/0emB2RKFOWxuIsPyS"
  }

  depends_on = [google_container_cluster.cluster]
}

resource "kubernetes_secret_v1" "cluster" {
  
  provider = kubernetes.gke

  metadata {
    name        = local.argocd_secret.name
    namespace   = local.argocd_secret.namespace
    annotations = local.argocd_secret.annotations
    labels      = local.argocd_secret.labels
  }
  data = local.argocd_secret.stringData

  depends_on = [helm_release.argocd]
}

locals {
  roles = flatten([
    for sa in local.workload_identity_service_accounts : [
      for role in sa.roles : {
        service_account = sa.name
        namespace       = coalesce(sa.namespace, sa.name)
        role            = role.name
        project         = try(role.project, null)
      }
    ]
  ])
  service_accounts = { for sa in local.workload_identity_service_accounts : sa.name => sa }
}

resource "google_service_account" "gcp_service_account" {
  for_each     = local.service_accounts
  account_id   = each.key
  display_name = "${each.key} Service Account"
  project      = var.project_id
}

resource "kubernetes_namespace" "namespace" {

  provider = kubernetes.gke

  for_each = local.service_accounts
  metadata {
    name = coalesce(each.value.namespace, each.key)
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "kubernetes_service_account" "kubernetes_service_account" {

  provider = kubernetes.gke

  depends_on = [ google_service_account.gcp_service_account ]
  for_each   = local.service_accounts
  metadata {
    name      = each.key
    namespace = coalesce(each.value.namespace, each.key)
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.gcp_service_account[each.key].email
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels
     ]
  }
}

resource "helm_release" "bootstrap" {

  provider = helm.gke 

  for_each = local.argocd_apps

  name      = each.key
  namespace = "argocd"
  chart     = "../charts"
  version   = "1.0.0"

  values = [
    <<-EOT
    resources:
      - ${indent(4, each.value)}
    EOT
  ]

  depends_on = [kubernetes_secret_v1.cluster]
}


# module "gitops_bridge_bootstrap" {
#   source = "../modules/helm_gitops_bridge"
#   apps   = local.argocd_apps
#   argocd = {
#     namespace = "argocd"
#     values    = [local.argo_values]
#     atomic    = true
#     skip_crds = false
#   }
#   cluster = {
#     cluster_name = google_container_cluster.cluster.name
#     environment  = "dev"
#     metadata     = local.metadata
#     addons = merge(
#       local.addons,
#       {
#         enable_argocd           = true
#         enable_cert_manager     = true
#         enable_external_dns     = true
#       }
#     )
#   }
# }