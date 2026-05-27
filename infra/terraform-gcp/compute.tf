resource "google_compute_instance" "app" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = [
    "${var.instance_name}-http",
    "${var.instance_name}-ssh",
  ]

  boot_disk {
    initialize_params {
      # Ubuntu 22.04 LTS minimal, amd64. The minimal image is ~700 MB so
      # it leaves more room on the 30 GB always-free disk.
      image = "ubuntu-os-cloud/ubuntu-minimal-2204-lts"
      size  = var.boot_disk_size_gb
      type  = "pd-standard" # NOT pd-balanced/pd-ssd; standard is the free tier.
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.id

    access_config {
      # Empty block = ephemeral public IPv4 (free, vs. a static IP which costs).
    }
  }

  metadata = {
    # GCE convention: "<username>:<ssh-pubkey>" enables key-based login.
    ssh-keys  = "ubuntu:${var.ssh_public_key}"
    user-data = templatefile("${path.module}/cloud-init.yaml", {
      git_repo_url = var.git_repo_url
      git_branch   = var.git_branch
    })
  }

  labels = local.common_labels

  # Don't replace the VM if the boot image is updated upstream by Canonical;
  # we only care about a deliberate re-deploy.
  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image,
    ]
  }
}
