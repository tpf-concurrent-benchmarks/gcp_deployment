resource "google_compute_instance" "vms" {
  zone         = var.zone
  count        = var.vm_count
  machine_type = count.index == 0 ? "n2-standard-2" : "n1-standard-1"
  name         = "vm-${count.index}"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size = count.index == 0 ? 50 : 10
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.subnet.name
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.default.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("../key.pub")}"
  }
}
