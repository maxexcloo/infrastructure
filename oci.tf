data "oci_core_ipv6s" "config" {
  for_each = data.oci_core_vnic_attachments.config

  vnic_id = each.value.vnic_attachments[0].id
}

data "oci_core_vnic" "config" {
  for_each = data.oci_core_vnic_attachments.config

  vnic_id = each.value.vnic_attachments[0].vnic_id
}

data "oci_core_vnic_attachments" "config" {
  for_each = oci_core_instance.config

  compartment_id = var.terraform.oci.tenancy_ocid
  instance_id    = each.value.id
}

data "oci_identity_availability_domain" "config" {
  ad_number      = 1
  compartment_id = var.terraform.oci.tenancy_ocid
}

resource "oci_core_default_dhcp_options" "config" {
  compartment_id             = var.terraform.oci.tenancy_ocid
  display_name               = "${var.terraform.oci.location}.${var.root.domain}"
  manage_default_resource_id = oci_core_vcn.config.default_dhcp_options_id

  options {
    server_type = "VcnLocalPlusInternet"
    type        = "DomainNameServer"
  }

  options {
    search_domain_names = [oci_core_vcn.config.vcn_domain_name]
    type                = "SearchDomain"
  }
}

resource "oci_core_default_route_table" "config" {
  display_name               = "${var.terraform.oci.location}.${var.root.domain}"
  manage_default_resource_id = oci_core_vcn.config.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.config.id
  }

  route_rules {
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.config.id
  }
}

resource "oci_core_default_security_list" "config" {
  compartment_id             = var.terraform.oci.tenancy_ocid
  display_name               = "${var.terraform.oci.location}.${var.root.domain}"
  manage_default_resource_id = oci_core_vcn.config.default_security_list_id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  egress_security_rules {
    destination = "::/0"
    protocol    = "all"
    stateless   = false
  }

  ingress_security_rules {
    protocol  = "all"
    source    = "0.0.0.0/0"
    stateless = false
  }

  ingress_security_rules {
    protocol  = "all"
    source    = "::/0"
    stateless = false
  }
}

resource "oci_core_instance" "config" {
  for_each = {
    for k, v in local.merged_servers : k => v
    if v.parent == "oci"
  }

  availability_domain = data.oci_identity_availability_domain.config.name
  compartment_id      = var.terraform.oci.tenancy_ocid
  display_name        = each.key
  shape               = each.value.config.shape

  metadata = {
    user_data = base64encode(templatefile(
      "${path.module}/templates/cloud_config.tftpl",
      {
        password       = random_password.server[each.key].bcrypt_hash
        ssh_keys       = data.github_user.config.ssh_keys
        tailscale_key  = tailscale_tailnet_key.config[each.key].key
        tailscale_name = tailscale_tailnet_key.config[each.key].description
        user           = each.value.user
      }
    ))
  }

  create_vnic_details {
    assign_ipv6ip             = true
    assign_private_dns_record = true
    assign_public_ip          = true
    display_name              = each.key
    hostname_label            = each.value.hostname
    subnet_id                 = oci_core_subnet.config.id
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
}

resource "oci_core_internet_gateway" "config" {
  compartment_id = var.terraform.oci.tenancy_ocid
  display_name   = "${var.terraform.oci.location}.${var.root.domain}"
  vcn_id         = oci_core_vcn.config.id
}

resource "oci_core_subnet" "config" {
  cidr_block     = "10.0.0.0/24"
  compartment_id = var.terraform.oci.tenancy_ocid
  display_name   = "${var.terraform.oci.location}.${var.root.domain}"
  dns_label      = var.terraform.oci.location
  ipv6cidr_block = replace(oci_core_vcn.config.ipv6cidr_blocks[0], "/56", "/64")
  vcn_id         = oci_core_vcn.config.id
}

resource "oci_core_vcn" "config" {
  cidr_blocks    = ["10.0.0.0/16"]
  compartment_id = var.terraform.oci.tenancy_ocid
  display_name   = "${var.terraform.oci.location}.${var.root.domain}"
  dns_label      = replace(var.root.domain, "/\\.[^.]*$/", "")
  is_ipv6enabled = true
}
