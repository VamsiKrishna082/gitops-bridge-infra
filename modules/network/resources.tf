# ----------------- #
# Network Resources #
# ----------------- #

resource "google_compute_network" "lab" {
  name                    = "${local.prefix}vpc-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges" {
  for_each = var.subnets

  name          = "${local.prefix}vpc-subnet-${each.key}"
  ip_cidr_range = each.value.ip_cidr_range
  region        = each.value.region
  network       = google_compute_network.lab.id
}
