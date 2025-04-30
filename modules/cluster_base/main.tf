#External Secrets
locals {
  kubernetes_secrets_sa_name = "external-secrets"
  argo_cd_sa_name            = "argocd-secrets"
  # argo_values = templatefile("${path.module}/templates/argo-values.tftpl", {
  #   argo_admin_password = random_password.argo_admin_password.result
  #   argo_client_id      = data.google_secret_manager_secret_version.argo_client_id.secret_data
  #   argo_client_secret  = data.google_secret_manager_secret_version.argo_client_secret.secret_data
  # })
}

# resource "google_service_account" "external_secrets_sa" {
#   account_id   = "external-secrets-sa"
#   display_name = "External Secrets Service Account"
#   project      = var.project_id
# }

# resource "kubernetes_namespace" "external_secrets" {
#   metadata {
#     annotations = {
#       name                             = var.external_secrets_namespace
#       "iam.gke.io/gcp-service-account" = google_service_account.external_secrets_sa.email
#     }

#     labels = {
#       environment = "production"
#     }

#     name = var.external_secrets_namespace
#   }
# }

# resource "kubernetes_service_account" "external_secrets" {
#   metadata {
#     name = local.kubernetes_secrets_sa_name
#   }
# }

# resource "google_service_account_iam_binding" "external_secrets_wl_id" {
#   service_account_id = google_service_account.external_secrets_sa.name
#   role               = "roles/iam.workloadIdentityUser"
#   members            = ["serviceAccount:${var.project_id}.svc.id.goog[${var.external_secrets_namespace}/${local.kubernetes_secrets_sa_name}]"]
# }

# resource "helm_release" "external_secrets" {
#   name       = "external-secrets"
#   namespace  = var.external_secrets_namespace
#   repository = "https://charts.external-secrets.io"
#   chart      = "external-secrets"
#   version    = var.external_secrets_helm_chart_version

#   # set {
#   #   name  = "serviceAccount.annotations.iam.gke.io/gcp-service-account"
#   #   value = google_service_account.external_secrets_sa.email
#   # }

#   set {
#     name  = "k8s.secretStore"
#     value = "google"
#   }

#   set {
#     name  = "gcp.projectId"
#     value = var.project_id
#   }

#   set {
#     name  = "installCRDs"
#     value = "true"
#   }
# }

# ArgoCD

data "google_secret_manager_secret" "argo_client_id" {
  secret_id = "argocd-client-id"
  project   = var.project_id
}

data "google_secret_manager_secret" "argo_client_secret" {
  secret_id = "argocd-client-secret"
  project   = var.project_id
}

data "google_secret_manager_secret_version" "argo_client_id" {
  secret  = data.google_secret_manager_secret.argo_client_id.name
  version = "latest"
}

data "google_secret_manager_secret_version" "argo_client_secret" {
  secret  = data.google_secret_manager_secret.argo_client_secret.name
  version = "latest"
}

data "google_secret_manager_secret" "existing_secrets" {
  for_each  = toset(var.existing_secrets)
  secret_id = each.value
  project   = var.project_id
}

# resource "google_secret_manager_secret_iam_member" "existing_secrets_perms" {
#   for_each  = toset(var.existing_secrets)
#   secret_id = data.google_secret_manager_secret.existing_secrets[each.value].id
#   role      = "roles/secretmanager.secretAccessor"
#   member    = "serviceAccount:${google_service_account.argo_cd_secrets_account.email}"
# }

# resource "google_service_account" "argo_cd_secrets_account" {
#   account_id   = "argocd-secrets"
#   display_name = "ArgoCD Secrets SA"
#   project      = var.project_id
# }

# resource "kubernetes_service_account" "argo_cd_k8s_sa" {
#   metadata {
#     name      = local.argo_cd_sa_name
#     namespace = var.argo_namespace
#     annotations = {
#       "iam.gke.io/gcp-service-account" = google_service_account.argo_cd_secrets_account.email
#     }
#   }
# }

# resource "google_project_iam_member" "identity_permissions" {
#   project  = var.project_id
#   role     = "roles/iam.serviceAccountTokenCreator"
#   member   = "serviceAccount:${google_service_account.argo_cd_secrets_account.email}"
# }

# resource "google_service_account_iam_binding" "argocd_wl_id" {
#   service_account_id = google_service_account.argo_cd_secrets_account.name
#   role               = "roles/iam.workloadIdentityUser"
#   members            = ["serviceAccount:${var.project_id}.svc.id.goog[${var.argo_namespace}/${local.argo_cd_sa_name}]"]
# }

# resource "google_secret_manager_secret_iam_member" "argo_client_id_perm" {
#   secret_id = data.google_secret_manager_secret.argo_client_secret.id
#   role      = "roles/secretmanager.secretAccessor"
#   member    = "serviceAccount:${google_service_account.argo_cd_secrets_account.email}"
# }

# resource "google_secret_manager_secret_iam_member" "argo_client_secret_perm" {
#   secret_id = data.google_secret_manager_secret.argo_client_id.id
#   role      = "roles/secretmanager.secretAccessor"
#   member    = "serviceAccount:${google_service_account.argo_cd_secrets_account.email}"
# }

# resource "helm_release" "argocd" {
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd"
#   version    = var.argo_helm_chart_version
#   atomic     = true

#   name      = "argocd"
#   namespace = var.argo_namespace

#   values = [
#     local.argo_values
#   ]

#   set_sensitive {
#     name  = "values_checksum"
#     value = sha256(local.argo_values)
#   }

#   depends_on = [kubectl_manifest.argo_cd_secrets, kubernetes_namespace.argocd_namespace, helm_release.external_secrets]
# }

# resource "kubernetes_namespace" "argocd_namespace" {
#   metadata {
#     annotations = {
#       name = var.argo_namespace
#     }

#     labels = {
#       environment = "production"
#     }

#     name = var.argo_namespace
#   }
# }

# client id and client secret need to be created and put in secret manager before hand these are configured in API & Services > Credentials > OAuth Client ID > webapp
# resource "kubectl_manifest" "argo_cd_secrets" {
#   depends_on = [kubernetes_namespace.argocd_namespace, kubectl_manifest.argo_cd_secretstore]
#   yaml_body  = <<YAML
# apiVersion: external-secrets.io/v1beta1
# kind: ExternalSecret
# metadata:
#   name: argo-cd-secrets
#   namespace: ${var.argo_namespace}
#   labels:
#     app.kubernetes.io/part-of: argocd
# spec:
#   refreshInterval: 1h
#   secretStoreRef:
#     kind: SecretStore
#     name: argocd-secretstore
#   data:
#     - secretKey: client_id
#       remoteRef:
#         key: argocd-client-id
#     - secretKey: client_secret
#       remoteRef:
#         key: argocd-client-secret
# YAML

#   lifecycle {
#     ignore_changes = all
#   }
# }

# This Secret also needs to be created in advance. These are created in Github
# resource "kubectl_manifest" "argo_apps" {
#   depends_on = [kubernetes_namespace.argocd_namespace, kubectl_manifest.argo_cd_secretstore, google_secret_manager_secret_iam_member.existing_secrets_perms]
#   yaml_body  = <<YAML
# apiVersion: external-secrets.io/v1beta1
# kind: ExternalSecret
# metadata:
#   name: argo-cd-app-repository
#   namespace: ${var.argo_namespace}
# spec:
#   target:
#     template:
#       engineVersion: v2
#       metadata:
#         annotations:
#           managed-by: argocd.argoproj.io
#         labels:
#           argocd.argoproj.io/secret-type: repository
#       data:
#         type: git
#         url: https://github.com/Tensure/argocd-apps
#         name: argocd-apps
#         githubAppID: "{{ .githubAppID }}"
#         githubAppInstallationID: "{{ .githubAppInstallationID }}"
#         githubAppPrivateKey: "{{ .githubAppPrivateKey }}"
#   refreshInterval: 1h
#   secretStoreRef:
#     kind: SecretStore
#     name: argocd-secretstore
#   data:
#     - secretKey: githubAppID
#       remoteRef:
#         key: apps-github-app-id
#     - secretKey: githubAppInstallationID
#       remoteRef:
#         key: apps-github-app-installation-id
#     - secretKey: githubAppPrivateKey
#       remoteRef:
#         key: apps-github-app-private-key
# YAML

#   lifecycle {
#     ignore_changes = all
#   }
# }

# resource "kubectl_manifest" "argo_manifests" {
#   depends_on = [kubernetes_namespace.argocd_namespace, kubectl_manifest.argo_cd_secretstore, google_secret_manager_secret_iam_member.existing_secrets_perms]
#   yaml_body  = <<YAML
# apiVersion: external-secrets.io/v1beta1
# kind: ExternalSecret
# metadata:
#   name: argocd-manifest-repository
#   namespace: ${var.argo_namespace}
# spec:
#   target:
#     template:
#       engineVersion: v2
#       metadata:
#         annotations:
#           managed-by: argocd.argoproj.io
#         labels:
#           argocd.argoproj.io/secret-type: repository
#       data:
#         type: git
#         url: https://github.com/Tensure/argocd-manifests
#         name: argocd-manifests
#         githubAppID: "{{ .githubAppID }}"
#         githubAppInstallationID: "{{ .githubAppInstallationID }}"
#         githubAppPrivateKey: "{{ .githubAppPrivateKey }}"
#   refreshInterval: 1h
#   secretStoreRef:
#     kind: SecretStore
#     name: argocd-secretstore
#   data:
#     - secretKey: githubAppID
#       remoteRef:
#         key: apps-github-app-id
#     - secretKey: githubAppInstallationID
#       remoteRef:
#         key: apps-github-app-installation-id
#     - secretKey: githubAppPrivateKey
#       remoteRef:
#         key: apps-github-app-private-key
# YAML

#   lifecycle {
#     ignore_changes = all
#   }
# }

# resource "kubectl_manifest" "argo_cd_secretstore" {
#   depends_on = [kubernetes_namespace.argocd_namespace, helm_release.external_secrets]
#   yaml_body  = <<YAML
# apiVersion: external-secrets.io/v1beta1
# kind: SecretStore
# metadata:
#   name: argocd-secretstore
#   namespace: ${var.argo_namespace}
# spec:
#   provider:
#     gcpsm:
#       auth:
#         workloadIdentity:
#           clusterName: ${var.cluster_config.name}
#           clusterProjectID: ${var.project_id}
#           clusterLocation: ${var.cluster_config.location}
#           serviceAccountRef:
#             name: ${local.argo_cd_sa_name}
#       projectID: ${var.project_id}
# YAML

#   lifecycle {
#     ignore_changes = all
#   }
# }

# resource "kubectl_manifest" "argo_cd_cluster_secret" {
#   depends_on = [kubernetes_namespace.argocd_namespace]
#   yaml_body  = <<YAML
# apiVersion: v1
# kind: Secret
# metadata:
#   name: argocd-local-cluster-name
#   namespace: ${var.argo_namespace}
#   labels:
#     argocd.argoproj.io/secret-type: cluster
# type: Opaque
# stringData:
#   name: ${var.cluster_config.name}
#   server: https://kubernetes.default.svc
#   config: |-
#     {
#       "tlsClientConfig": {
#         "insecure": false
#       }
#     }
# YAML

#   lifecycle {
#     ignore_changes = all
#   }
# }

# resource "random_password" "argo_admin_password" {
#   length           = 16
#   special          = true
#   override_special = "!*()-=+-_"
# }
