resource "google_filestore_instance" "default" {
  # Do not create the resource if the variable is false
  count = var.create_filestore ? 1 : 0

  project = var.project_id
  location = var.zone
  tier = "BASIC_HDD"
  name = "filestore"

  file_shares {
    capacity_gb = 1024
    name        = "share1"
  }

  networks {
    network = google_compute_network.vpc.name
    modes   = ["MODE_IPV4"]
  }
}

output "filestore_ip" {
  value = var.create_filestore ? google_filestore_instance.default[0].networks[0].ip_addresses[0] : null
}

output "filestore_share_name" {
  value = var.create_filestore ? google_filestore_instance.default[0].file_shares[0].name : null
}