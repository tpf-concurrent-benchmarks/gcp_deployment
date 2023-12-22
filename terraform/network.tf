resource "google_compute_network" "vpc" {
  name                    = "network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "subnet"
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
}

## Create Cloud Router

resource "google_compute_router" "router" {
  name    = "nat-router"
  region  = google_compute_subnetwork.subnet.region
  network = google_compute_network.vpc.name

  bgp {
    asn = 64514
  }
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  name                               = "router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "ssh-rule" {
  name = "allow-ssh"
  network = google_compute_network.vpc.name
  direction = "INGRESS"
  priority = 200
  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "http-apps-rule" {
  name = "allow-http-apps-ports"
  network = google_compute_network.vpc.name
  direction = "INGRESS"
  priority = 1000
  allow {
    protocol = "tcp"
    ports = ["8080", "8081", "15672"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "internal-rule" {
  name = "allow-internal"
  network = google_compute_network.vpc.name
  direction = "INGRESS"
  priority = 5000
  allow {
    protocol = "all"
  }

  source_ranges = [google_compute_subnetwork.subnet.ip_cidr_range]
}