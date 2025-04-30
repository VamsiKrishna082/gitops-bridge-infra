variable "create_k8s_resources" {
  type = bool
  default = true
}

variable "project_id" {
  type        = string
  description = "The project id"
}

variable "service_account_map" {
  type = list(object({
    name      = string
    roles     = list(object({
      name = string
      project = optional(string)
    }))
    namespace = optional(string)
  }))
  description = <<-EOF
  List of service accounts and their roles.
  Each service Account object should have a name
  and a list of roles to be assigned to the service account.
  Optionally you can set a namespace in case the namespace and service
  account names don't match.
  - name: The name of the service account
  - roles: A list of role maps to be assigned to the service account. Consists of two properties: 'name' and 'project'
  - namespace: namespace over ride if the namespace is different than the service account name
  - project: override the project to give permissions for

  [{
    name = "cert-manager"
    roles = [
      {
        name = "roles/dns.admin"
        project = "apps-project"
      }
    ]
  }]
  EOF
}