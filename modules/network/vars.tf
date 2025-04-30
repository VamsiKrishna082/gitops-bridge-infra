# --------- #
# Variables #
# --------- #

variable "gcp" {
  description = "GCP configuration"
  type = object({
    project_id = string
    region     = string
  })
}

variable "subnets" {
  description = "Subnets configuration"
  type = map(
    object({
      ip_cidr_range = string
      region        = string
    })
  )
}