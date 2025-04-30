#GCP Service Accounts
locals {
  roles = flatten([
    for sa in var.service_account_map : [
      for role in sa.roles : {
        service_account = sa.name
        namespace       = coalesce(sa.namespace, sa.name)
        role            = role.name
        project         = try(role.project, null)
      }
    ]
  ])
  service_accounts = { for sa in var.service_account_map : sa.name => sa }
}
resource "google_service_account" "gcp_service_account" {
  for_each     = local.service_accounts
  account_id   = each.key
  display_name = "${each.key} Service Account"
  project      = var.project_id
}

resource "kubernetes_namespace" "namespace" {

  for_each = var.create_k8s_resources ? local.service_accounts : {}
  metadata {
    name = coalesce(each.value.namespace, each.key)
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "kubernetes_service_account" "kubernetes_service_account" {

  depends_on = [ google_service_account.gcp_service_account ]
  for_each   = var.create_k8s_resources ? local.service_accounts : {}
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

resource "google_service_account_iam_binding" "workload_identity" {
  for_each           = local.service_accounts
  service_account_id = google_service_account.gcp_service_account[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${var.project_id}.svc.id.goog[${coalesce(each.value.namespace, each.value.name)}/${each.value.name}]"]
}



resource "google_project_iam_member" "identity_permissions" {
  for_each = { for role in local.roles : "${coalesce(role.project, var.project_id)}-${role.service_account}-${role.role}" => role }
  project  = coalesce(each.value.project, var.project_id)
  role     = each.value.role
  member   = "serviceAccount:${google_service_account.gcp_service_account[each.value.service_account].email}"
}