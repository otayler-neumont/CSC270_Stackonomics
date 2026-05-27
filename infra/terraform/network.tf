# A minimal public VCN: one regional subnet with an Internet Gateway and
# stateful security-list rules allowing SSH (configurable CIDR) and HTTP
# from anywhere. Everything here is free.

resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.instance_name}-vcn"
  cidr_blocks    = ["10.20.0.0/16"]
  dns_label      = "stack"
  freeform_tags  = local.common_tags
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.instance_name}-igw"
  enabled        = true
  freeform_tags  = local.common_tags
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.instance_name}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this.id
  }

  freeform_tags = local.common_tags
}

resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.instance_name}-public-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  # SSH
  ingress_security_rules {
    source    = var.allowed_ssh_cidr
    protocol  = "6" # TCP
    stateless = false
    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP (the app is published on :80 directly by docker-compose.prod.yml)
  ingress_security_rules {
    source    = "0.0.0.0/0"
    protocol  = "6"
    stateless = false
    tcp_options {
      min = 80
      max = 80
    }
  }

  # ICMP (helpful for ping/path-MTU discovery)
  ingress_security_rules {
    source    = "0.0.0.0/0"
    protocol  = "1"
    stateless = false
    icmp_options {
      type = 3
      code = 4
    }
  }

  freeform_tags = local.common_tags
}

resource "oci_core_subnet" "public" {
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.this.id
  display_name        = "${var.instance_name}-public-subnet"
  cidr_block          = "10.20.1.0/24"
  route_table_id      = oci_core_route_table.public.id
  security_list_ids   = [oci_core_security_list.public.id]
  prohibit_public_ip_on_vnic = false
  dns_label           = "public"
  freeform_tags       = local.common_tags
}
