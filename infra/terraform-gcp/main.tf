provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = file(var.credentials_file)
}

locals {
  common_labels = {
    project = "stackonomics"
    phase   = "phase-4"
  }
}
