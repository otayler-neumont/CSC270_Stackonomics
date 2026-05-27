provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# First availability domain in the region. The Always-Free ARM A1 Flex shape
# is available in at least one AD per home region; OCI will surface a clear
# error here if it isn't.
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

locals {
  ad_count            = length(data.oci_identity_availability_domains.ads.availability_domains)
  # Wrap the index into the available ADs so the retry loop can pass 0/1/2/0/1/2...
  # without worrying about overshooting if some region has fewer ADs.
  ad_index            = var.availability_domain_index % local.ad_count
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[local.ad_index].name

  common_tags = {
    "project" = "stackonomics"
    "phase"   = "phase-4"
  }
}
