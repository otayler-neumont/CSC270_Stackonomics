# ---------------------------------------------------------------------------
# OCI authentication (all six come from your Oracle Cloud API key setup)
# ---------------------------------------------------------------------------

variable "tenancy_ocid" {
  description = "OCID of your OCI tenancy (Profile menu -> Tenancy)."
  type        = string
}

variable "user_ocid" {
  description = "OCID of the OCI user the API key belongs to."
  type        = string
}

variable "fingerprint" {
  description = "API key fingerprint shown after uploading the public key."
  type        = string
}

variable "private_key_path" {
  description = "Local filesystem path to the API private key (PEM)."
  type        = string
}

variable "region" {
  description = "OCI home region, e.g. us-ashburn-1, us-phoenix-1, sa-saopaulo-1."
  type        = string
  default     = "us-ashburn-1"
}

variable "compartment_ocid" {
  description = "OCID of the compartment to deploy into. Use the tenancy OCID to deploy to the root compartment."
  type        = string
}

# ---------------------------------------------------------------------------
# Instance configuration
# ---------------------------------------------------------------------------

variable "instance_name" {
  description = "Display name for the VM and related network resources."
  type        = string
  default     = "stackonomics"
}

variable "shape" {
  description = "OCI shape. Default targets the Always-Free ARM Ampere A1 Flex tier."
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "ocpus" {
  description = "Number of OCPUs. Always-Free ARM allowance is 4 OCPUs total across instances."
  type        = number
  default     = 2
}

variable "memory_in_gbs" {
  description = "Memory in GB. Always-Free ARM allowance is 24 GB total across instances."
  type        = number
  default     = 12
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size in GB. Always-Free includes up to 200 GB of block storage."
  type        = number
  default     = 50
}

# ---------------------------------------------------------------------------
# Access
# ---------------------------------------------------------------------------

variable "ssh_public_key" {
  description = "SSH public key (contents, not a path) authorized to log in as 'ubuntu'."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to reach port 22. Set to your IP/32 for safety; 0.0.0.0/0 opens SSH to the world."
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
