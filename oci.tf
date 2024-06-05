data "oci_core_ipv6s" "vm" {
  for_each = data.oci_core_vnic_attachments.vm

  vnic_id = each.value.vnic_attachments[0].id
}

data "oci_core_vnic" "vm" {
  for_each = data.oci_core_vnic_attachments.vm

  vnic_id = each.value.vnic_attachments[0].vnic_id
}

data "oci_core_vnic_attachments" "vm" {
  for_each = oci_core_instance.vm

  compartment_id = var.terraform.oci.tenancy_ocid
  instance_id    = each.value.id
}

data "oci_identity_availability_domain" "au" {
  ad_number      = 1
  compartment_id = var.terraform.oci.tenancy_ocid
}

resource "oci_core_default_dhcp_options" "au" {
  compartment_id             = var.terraform.oci.tenancy_ocid
  display_name               = "${var.terraform.oci.location}.${var.default.domain_external}"
  manage_default_resource_id = oci_core_vcn.au.default_dhcp_options_id

  options {
    server_type = "VcnLocalPlusInternet"
    type        = "DomainNameServer"
  }

  options {
    search_domain_names = [oci_core_vcn.au.vcn_domain_name]
    type                = "SearchDomain"
  }
}

resource "oci_core_default_route_table" "au" {
  display_name               = "${var.terraform.oci.location}.${var.default.domain_external}"
  manage_default_resource_id = oci_core_vcn.au.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.au.id
  }

  route_rules {
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.au.id
  }
}

resource "oci_core_default_security_list" "au" {
  compartment_id             = var.terraform.oci.tenancy_ocid
  display_name               = "${var.terraform.oci.location}.${var.default.domain_external}"
  manage_default_resource_id = oci_core_vcn.au.default_security_list_id

  egress_security_rules {
    destination = "::/0"
    protocol    = "all"
    stateless   = false
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  ingress_security_rules {
    protocol  = 1
    source    = "::/0"
    stateless = false
  }

  ingress_security_rules {
    protocol  = 6
    source    = "::/0"
    stateless = false

    tcp_options {
      max = 22
      min = 22
    }
  }

  ingress_security_rules {
    protocol  = 6
    source    = "::/0"
    stateless = false

    tcp_options {
      max = 80
      min = 80
    }
  }

  ingress_security_rules {
    protocol  = 6
    source    = "::/0"
    stateless = false

    tcp_options {
      max = 443
      min = 443
    }
  }

  ingress_security_rules {
    protocol  = 1
    source    = "0.0.0.0/0"
    stateless = false
  }

  ingress_security_rules {
    protocol  = 6
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      max = 22
      min = 22
    }
  }

  ingress_security_rules {
    protocol  = 6
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      max = 80
      min = 80
    }
  }

  ingress_security_rules {
    protocol  = 6
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      max = 443
      min = 443
    }
  }
}

resource "oci_core_instance" "vm" {
  for_each = local.vms_oci

  availability_domain = data.oci_identity_availability_domain.au.name
  compartment_id      = var.terraform.oci.tenancy_ocid
  display_name        = each.key
  shape               = each.value.config.shape

  metadata = {
    user_data = base64encode(templatefile(
      "./templates/cloud_config/cloud_config.tftpl",
      {
        password      = htpasswd_password.server[each.key].sha512
        server        = each.value
        ssh_key       = trimspace(tls_private_key.server_ssh_key[each.key].public_key_openssh)
        tailscale_key = tailscale_tailnet_key.server[each.key].key
      }
    ))
  }

  create_vnic_details {
    assign_ipv6ip             = true
    assign_private_dns_record = true
    assign_public_ip          = true
    display_name              = each.key
    hostname_label            = each.value.name
    subnet_id                 = oci_core_subnet.au.id
  }

  shape_config {
    memory_in_gbs = each.value.config.memory
    ocpus         = each.value.config.cpus
  }

  source_details {
    boot_volume_size_in_gbs = each.value.config.disk_size
    source_id               = each.value.config.boot_image_id
    source_type             = each.value.config.boot_image_type
  }

  lifecycle {
    ignore_changes = [
      metadata["user_data"]
    ]
  }
}

resource "oci_core_internet_gateway" "au" {
  compartment_id = var.terraform.oci.tenancy_ocid
  display_name   = "${var.terraform.oci.location}.${var.default.domain_external}"
  vcn_id         = oci_core_vcn.au.id
}

resource "oci_core_subnet" "au" {
  cidr_block     = "10.0.0.0/24"
  compartment_id = var.terraform.oci.tenancy_ocid
  display_name   = "${var.terraform.oci.location}.${var.default.domain_external}"
  dns_label      = var.terraform.oci.location
  ipv6cidr_block = replace(oci_core_vcn.au.ipv6cidr_blocks[0], "/56", "/64")
  vcn_id         = oci_core_vcn.au.id
}

resource "oci_core_vcn" "au" {
  cidr_blocks    = ["10.0.0.0/16"]
  compartment_id = var.terraform.oci.tenancy_ocid
  display_name   = "${var.terraform.oci.location}.${var.default.domain_external}"
  dns_label      = replace(var.default.domain_external, "/\\.[^.]*$/", "")
  is_ipv6enabled = true
}
