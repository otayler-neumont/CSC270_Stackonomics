# ---------------------------------------------------------------------------
# GCP project + auth
# ---------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID (NOT the project number). Find it in the Console top bar."
  type        = string
}

variable "credentials_file" {
  description = "Local filesystem path to the service-account JSON key authorized for Compute Admin in this project."
  type        = string
}

# ---------------------------------------------------------------------------
# Location (always-free e2-micro must be in one of these three regions)
# ---------------------------------------------------------------------------

variable "region" {
  description = "GCP region. Must be us-west1, us-central1, or us-east1 to stay always-free."
  type        = string
  default     = "us-central1"

  validation {
    condition     = contains(["us-west1", "us-central1", "us-east1"], var.region)
    error_message = "e2-micro is only always-free in us-west1, us-central1, or us-east1."
  }
}

variable "zone" {
  description = "GCP zone within the region (e.g. us-central1-a)."
  type        = string
  default     = "us-central1-a"
}

# ---------------------------------------------------------------------------
# Instance configuration
# ---------------------------------------------------------------------------

variable "instance_name" {
  description = "Display name for the VM and related network resources."
  type        = string
  default     = "stackonomics"
}

variable "machine_type" {
  description = "GCE machine type. e2-micro is the always-free shape (0.25 vCPU burst to 2, 1 GB RAM)."
  type        = string
  default     = "e2-micro"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB. Always-free includes up to 30 GB of standard persistent disk."
  type        = number
  default     = 30
}

# ---------------------------------------------------------------------------
# Access
# ---------------------------------------------------------------------------

variable "ssh_public_key" {
  description = "SSH public key (contents, not a path) authorized to log in as 'ubuntu'."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to reach port 22. 0.0.0.0/0 leaves SSH open to the world."
  type        = string
  default     = "0.0.0.0/0"
}

# ---------------------------------------------------------------------------
# App deployment
# ---------------------------------------------------------------------------

variable "git_repo_url" {
  description = "HTTPS URL of the public Git repo to clone on the VM."
  type        = string
  default     = "https://github.com/otayler-neumont/CSC270_Stackonomics.git"
}

variable "git_branch" {
  description = "Branch to deploy."
  type        = string
  default     = "phase4-docker"
}
