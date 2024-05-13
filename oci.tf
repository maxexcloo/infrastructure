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

  compartment_id = var.oci.tenancy_ocid
  instance_id    = each.value.id
}

data "oci_identity_availability_domain" "au" {
  ad_number      = 1
  compartment_id = var.oci.tenancy_ocid
}

resource "oci_core_default_dhcp_options" "au" {
  compartment_id             = var.oci.tenancy_ocid
  display_name               = "${var.oci.location}.${var.root_domain}"
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
  display_name               = "${var.oci.location}.${var.root_domain}"
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
  compartment_id             = var.oci.tenancy_ocid
  display_name               = "${var.oci.location}.${var.root_domain}"
  manage_default_resource_id = oci_core_vcn.au.default_security_list_id

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
    for i, server in var.servers : "${server.hostname}.${server.location}.${var.root_domain}" => server
    if server.type == "oci"
  }

  availability_domain = data.oci_identity_availability_domain.au.name
  compartment_id      = var.oci.tenancy_ocid
  display_name        = each.key
  shape               = each.value.config.shape

  metadata = {
    ssh_authorized_keys = join("\n", data.github_user.config.ssh_keys)
  }

  create_vnic_details {
    assign_ipv6ip             = true
    assign_private_dns_record = true
    assign_public_ip          = true
    display_name              = each.key
    hostname_label            = each.value.hostname
    subnet_id                 = oci_core_subnet.au.id
  }

  shape_config {
    memory_in_gbs = each.value.config.memory
    ocpus         = each.value.config.cpus
  }

  source_details {
    boot_volume_size_in_gbs = each.value.config.disk_size
    source_id               = each.value.config.disk_image_id
    source_type             = each.value.config.disk_image_type
  }
}

resource "oci_core_internet_gateway" "au" {
  compartment_id = var.oci.tenancy_ocid
  display_name   = "${var.oci.location}.${var.root_domain}"
  vcn_id         = oci_core_vcn.au.id
}

resource "oci_core_subnet" "au" {
  cidr_block     = "10.0.0.0/24"
  compartment_id = var.oci.tenancy_ocid
  display_name   = "${var.oci.location}.${var.root_domain}"
  dns_label      = var.oci.location
  ipv6cidr_block = replace(oci_core_vcn.au.ipv6cidr_blocks[0], "/56", "/64")
  vcn_id         = oci_core_vcn.au.id
}

resource "oci_core_vcn" "au" {
  cidr_blocks    = ["10.0.0.0/16"]
  compartment_id = var.oci.tenancy_ocid
  display_name   = "${var.oci.location}.${var.root_domain}"
  dns_label      = replace(var.root_domain, "/\\.[^.]*$/", "")
  is_ipv6enabled = true
}