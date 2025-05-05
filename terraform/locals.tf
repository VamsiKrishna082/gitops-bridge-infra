locals {
    cluster_name = "backstage-cluster"
    environment  = "dev"

    addons = {
        enable_argocd  = true
        enable_cert_manager = true
        enable_external_dns = true
        enable_external_secrets = true
    }

    prefix = "vamsi-krishna-sandbox"
    subnet = "default"
    vpc    = "default"
    labels = merge(var.labels,
        {
            owner       = "vamc-test",
            environment = "development"
        }
    )
    gke_k8s_version = "1.30.10-gke.1070000"

    # wl_id_service_account_emails = { for name, sa in module.workload_identity.gcp_service_accounts : "${replace(name, "-", "_")}_sa" => sa.email }

    cluster_sa_roles = {
        "roles/container.admin"         = "Container Admin"
        "roles/container.clusterAdmin"  = "Cluster Admin"
        "roles/container.developer"     = "Developer"
        "roles/iam.serviceAccountAdmin" = "Service Account Admin"
        "roles/artifactregistry.reader" = "Artifact Registry Reader"
        "roles/logging.logWriter"       = "Log Writer"
        "roles/monitoring.metricWriter" = "Metric Writer"
    }

    metadata = merge(
        {
            cluster_name         = local.cluster_name
            environment          = local.environment
            region               = var.region
            gcp_project_id       = var.project_id
            gcp_dns_project_id   = var.project_id
            gcp_vpc_id           = local.vpc
            argocd_sa                   = google_service_account.argocd.email
            cert_manager_namespace      = "cert-manager"
            external_dns_domain_filters = "ioinfo.shop"
            external_dns_namespace      = "external-dns"
            external_secrets_namespace = "external-secrets"
            managed-by           = "argocd.argoproj.io"
            argocd_namespace     = "argocd"
            addons_repo_url      = "https://github.com/VamsiKrishna082/gitops-bridge-automation.git"
            addons_repo_path     = "bootstrap/control-plane/addons"
            addons_repo_revision = "main"
            addons_name          = "addons-repo"
            addons_repo_basepath = ""
        },
        # local.wl_id_service_account_emails
    )
    

    annotations = local.metadata

    argocd_labels = merge({
        "argocd.argoproj.io/secret-type" = "cluster"
        cluster_name                     = local.cluster_name,
        environment                      = local.environment
    }, 
    local.addons)

    argocd_apps = {
        addons = file("../bootstrap/addons.yaml")
    }

    workload_identity_service_accounts = [
        {
            name      = "cert-manager"
            namespace = "cert-manager"
            roles = [
                {
                    name = "roles/dns.admin"
                }
            ]
        },
        {
            name      = "external-dns"
            namespace = "external-dns"
            roles = [
                {
                    name = "roles/dns.admin"
                }
            ]
        },
        {
            name      = "external-secrets"
            namespace = "external-secrets"
            roles = [
                {
                    name = "roles/secretmanager.secretAccessor"
                }
            ]
        }
    ]

    config = jsonencode({
        tlsClientConfig = { insecure = false }
    })

    argocd_secret = {
        name        = local.cluster_name
        namespace   = "argocd"
        annotations = local.annotations
        labels      = local.argocd_labels
        stringData = {
            name   = local.cluster_name
            server = "https://kubernetes.default.svc"
            config = local.config
        }
    }
}