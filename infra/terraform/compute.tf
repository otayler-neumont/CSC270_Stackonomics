# Look up the newest Canonical Ubuntu 22.04 image that supports our shape.
# Filtering by shape ensures we get the ARM build when shape = A1.Flex.
data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "app" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain
  display_name        = var.instance_name
  shape               = var.shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    hostname_label   = var.instance_name
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
      git_repo_url = var.git_repo_url
      git_branch   = var.git_branch
    }))
  }

  freeform_tags = local.common_tags

  # The cloud-init script reboots-friendly bootstrap takes ~3-5 minutes.
  # Terraform considers the instance ready once OCI marks it RUNNING; we
  # output a friendly note in outputs.tf telling the user to wait.
}
