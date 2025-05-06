#backstage sa
locals {
  backstage_secrets = {
    "${local.prefix}-backstage-auth"             = var.backstage_auth_secret
    "${local.prefix}-postgres-instance"          = random_password.postgres_password.result
    "${local.prefix}-oauth-client-id"            = var.google_oauth_client_id
    "${local.prefix}-oauth-client-secret"        = var.google_oauth_client_secret
    "${local.prefix}-backstage-db-password"      = var.backstage_db_password
    "${local.prefix}-backstage-github-key"       = var.backstage_github_key
    "${local.prefix}-cloud-sql-ip"               = var.cloud_sql_ip
    # "${local.prefix}-github-app-client-id"       = var.github_app_client_id
    # "${local.prefix}-github-app-client-secret"   = var.github_app_client_secret
    # "${local.prefix}-github-app-id"              = var.github_app_id
    # "${local.prefix}-github-app-installation-id" = var.github_app_installation_id
    # "${local.prefix}-github-app-private-key"     = var.github_app_private_key
    # "${local.prefix}-github-app-webhook-secret"  = var.github_app_webhook_secret
  }
  # labels = merge(var.labels,
  #   {
  #     owner       = "devops",
  #     environment = "production"
  #   }
  # )

  # subnet = local.tensure_shared_state.tensure_subnets.tensure-shared-apps-us-east1
  # vpc    = local.tensure_shared_state.tensure_vpc

}

resource "google_service_account" "backstage_sa" {
  account_id                   = "backstage-sa"
  display_name                 = "Backstage service account."
  create_ignore_already_exists = true
  project                      = var.project_id
}

resource "google_secret_manager_secret_iam_member" "backstage_secret_roles" {
  for_each  = local.backstage_secrets
  project   = var.project_id
  secret_id = google_secret_manager_secret.backstage_secret[each.key].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.backstage_sa.email}"
}

resource "google_service_account_iam_binding" "backstage_to_gke_role_binding" {
  service_account_id = google_service_account.backstage_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[backstage/backstage]"
  ]
}

#secrets

resource "random_password" "postgres_password" {
  length  = 32
  special = true
}

resource "google_secret_manager_secret" "backstage_secret" {
  for_each  = local.backstage_secrets
  secret_id = each.key
  project   = var.project_id
  labels    = local.labels
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "backstage_secret_version" {
  for_each    = local.backstage_secrets
  secret      = google_secret_manager_secret.backstage_secret[each.key].id
  secret_data = each.value
}

# -------- #
# Postgres #
# -------- #

resource "google_sql_database_instance" "postgres" {
  name                = "${local.prefix}-postgresql-instance"
  project             = var.project_id
  database_version    = var.postgres.version
  root_password       = random_password.postgres_password.result
  deletion_protection = false
  settings {
    tier        = var.postgres.tier
    user_labels = local.labels
  }
}