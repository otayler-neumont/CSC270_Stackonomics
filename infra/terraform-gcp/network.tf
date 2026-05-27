# Minimal custom-mode VPC + regional subnet so we don't depend on the
# project's default VPC (which some orgs disable). All of this is free.

resource "google_compute_network" "this" {
  name                    = "${var.instance_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  name          = "${var.instance_name}-subnet"
  ip_cidr_range = "10.30.1.0/24"
  region        = var.region
  network       = google_compute_network.this.id
}

# Open port 80 from anywhere; tag-scoped so we only apply it to the app VM.
resource "google_compute_firewall" "http" {
  name      = "${var.instance_name}-allow-http"
  network   = google_compute_network.this.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.instance_name}-http"]
}

# Open port 22 from configurable CIDR; tag-scoped too.
resource "google_compute_firewall" "ssh" {
  name      = "${var.instance_name}-allow-ssh"
  network   = google_compute_network.this.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_ssh_cidr]
  target_tags   = ["${var.instance_name}-ssh"]
}
