resource "proxmox_virtual_environment_download_file" "gen8" {
  for_each = {
    for k, vm in local.merged_vms_proxmox : k => vm
    if vm.config.boot_disk_image_url != "" && vm.parent_name == "gen8"
  }

  content_type   = "iso"
  datastore_id   = "local"
  file_name      = "${each.value.name}${endswith(each.value.config.boot_disk_image_url, ".iso") ? ".iso" : ".img"}"
  node_name      = each.value.parent
  overwrite      = false
  provider       = proxmox.gen8
  upload_timeout = 1800
  url            = each.value.config.boot_disk_image_url
}

resource "proxmox_virtual_environment_download_file" "kimbap" {
  for_each = {
    for k, vm in local.merged_vms_proxmox : k => vm
    if vm.config.boot_disk_image_url != "" && vm.parent_name == "kimbap"
  }

  content_type   = "iso"
  datastore_id   = "local"
  file_name      = "${each.value.name}${endswith(each.value.config.boot_disk_image_url, ".iso") ? ".iso" : ".img"}"
  node_name      = each.value.parent
  overwrite      = false
  provider       = proxmox.kimbap
  upload_timeout = 1800
  url            = each.value.config.boot_disk_image_url
}

resource "proxmox_virtual_environment_file" "gen8" {
  for_each = {
    for k, vm in local.merged_vms_proxmox : k => vm
    if endswith(vm.config.boot_disk_image_url, ".img") && vm.parent_name == "gen8"
  }

  content_type = "snippets"
  datastore_id = "local"
  node_name    = each.value.parent
  provider     = proxmox.gen8

  source_raw {
    file_name = "${each.value.name}.yaml"

    data = templatefile(
      "./templates/cloud_config/cloud_config.tftpl",
      {
        cloudflare_tunnel_token = cloudflare_zero_trust_tunnel_cloudflared.server[each.key].tunnel_token
        password                = htpasswd_password.server[each.key].sha512
        server                  = each.value
        ssh_key_default         = data.github_user.default.ssh_keys
        ssh_key_server          = trimspace(tls_private_key.server_ssh_key[each.key].public_key_openssh)
        tailscale_tailnet_key   = tailscale_tailnet_key.server[each.key].key
      }
    )
  }
}

resource "proxmox_virtual_environment_file" "kimbap" {
  for_each = {
    for k, vm in local.merged_vms_proxmox : k => vm
    if endswith(vm.config.boot_disk_image_url, ".img") && vm.parent_name == "kimbap"
  }

  content_type = "snippets"
  datastore_id = "local"
  node_name    = each.value.parent
  provider     = proxmox.kimbap

  source_raw {
    file_name = "${each.value.name}.yaml"

    data = templatefile(
      "./templates/cloud_config/cloud_config.tftpl",
      {
        cloudflare_tunnel_token = cloudflare_zero_trust_tunnel_cloudflared.server[each.key].tunnel_token
        password                = htpasswd_password.server[each.key].sha512
        server                  = each.value
        ssh_key_default         = data.github_user.default.ssh_keys
        ssh_key_server          = trimspace(tls_private_key.server_ssh_key[each.key].public_key_openssh)
        tailscale_tailnet_key   = tailscale_tailnet_key.server[each.key].key
      }
    )
  }
}

resource "proxmox_virtual_environment_vm" "gen8" {
  for_each = { for k, vm in local.merged_vms_proxmox : k => vm if vm.parent_name == "gen8" }

  bios          = "ovmf"
  machine       = "q35"
  name          = each.value.name
  node_name     = each.value.parent
  provider      = proxmox.gen8
  scsi_hardware = "virtio-scsi-single"

  cpu {
    cores = each.value.config.cpus
    type  = "x86-64-v2-AES"
  }

  disk {
    backup       = true
    datastore_id = "local-zfs"
    discard      = "on"
    file_format  = "raw"
    file_id      = endswith(each.value.config.boot_disk_image_url, ".img") ? proxmox_virtual_environment_download_file.gen8[each.key].id : null
    interface    = "virtio0"
    iothread     = true
    size         = each.value.config.boot_disk_size
  }

  efi_disk {
    datastore_id = "local-zfs"
    type         = "4m"
  }

  memory {
    dedicated = each.value.config.memory * 1024
    floating  = 0
  }

  network_device {
    firewall = true
  }

  operating_system {
    type = try(each.value.config.operating_system, "l26")
  }

  dynamic "agent" {
    for_each = endswith(each.value.config.boot_disk_image_url, ".img") ? [true] : []

    content {
      enabled = true
      trim    = true
    }
  }

  dynamic "cdrom" {
    for_each = endswith(each.value.config.boot_disk_image_url, ".iso") ? [true] : []

    content {
      enabled   = true
      file_id   = proxmox_virtual_environment_download_file.gen8[each.key].id
      interface = "ide0"
    }
  }

  dynamic "disk" {
    for_each = each.value.disks

    content {
      backup            = disk.value.backup
      datastore_id      = disk.value.external ? "" : "local-zfs"
      discard           = disk.value.discard
      file_format       = "raw"
      interface         = "virtio${disk.key + 1}"
      path_in_datastore = disk.value.path
      serial            = disk.value.serial
      size              = disk.value.size
    }
  }

  dynamic "initialization" {
    for_each = endswith(each.value.config.boot_disk_image_url, ".img") ? [true] : []

    content {
      datastore_id      = "local-zfs"
      interface         = "ide0"
      user_data_file_id = proxmox_virtual_environment_file.gen8[each.key].id

      ip_config {
        ipv4 {
          address = each.value.network.ipv4 == "dhcp" ? each.value.network.ipv4 : each.value.network.ipv4.address
          gateway = each.value.network.ipv4 == "dhcp" ? null : each.value.network.ipv4.gateway
        }
        ipv6 {
          address = each.value.network.ipv6 == "dhcp" ? each.value.network.ipv6 : each.value.network.ipv6.address
          gateway = each.value.network.ipv6 == "dhcp" ? null : each.value.network.ipv6.gateway
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      initialization
    ]
  }
}

resource "proxmox_virtual_environment_vm" "kimbap" {
  for_each = { for k, v in local.merged_vms_proxmox : k => v if v.parent_name == "kimbap" }

  bios          = "ovmf"
  machine       = "q35"
  name          = each.value.name
  node_name     = each.value.parent
  provider      = proxmox.kimbap
  scsi_hardware = "virtio-scsi-single"

  cpu {
    cores = each.value.config.cpus
    type  = "x86-64-v2-AES"
  }

  disk {
    datastore_id = "local-zfs"
    discard      = "on"
    file_format  = "raw"
    file_id      = endswith(each.value.config.boot_disk_image_url, ".img") ? proxmox_virtual_environment_download_file.kimbap[each.key].id : null
    interface    = "virtio0"
    iothread     = true
    size         = each.value.config.boot_disk_size
  }

  efi_disk {
    datastore_id = "local-zfs"
    type         = "4m"
  }

  memory {
    dedicated = each.value.config.memory * 1024
    floating  = 0
  }

  network_device {
    firewall = true
  }

  operating_system {
    type = try(each.value.config.operating_system, "l26")
  }

  dynamic "agent" {
    for_each = endswith(each.value.config.boot_disk_image_url, ".img") ? [true] : []

    content {
      enabled = true
      trim    = true
    }
  }

  dynamic "cdrom" {
    for_each = endswith(each.value.config.boot_disk_image_url, ".iso") ? [true] : []

    content {
      enabled   = true
      file_id   = proxmox_virtual_environment_download_file.kimbap[each.key].id
      interface = "ide0"
    }
  }

  dynamic "disk" {
    for_each = each.value.disks

    content {
      backup            = disk.value.backup
      datastore_id      = disk.value.external ? "" : "local-zfs"
      discard           = disk.value.discard
      file_format       = "raw"
      interface         = "virtio${disk.key + 1}"
      path_in_datastore = disk.value.path
      serial            = disk.value.serial
      size              = disk.value.size
    }
  }

  dynamic "initialization" {
    for_each = endswith(each.value.config.boot_disk_image_url, ".img") ? [true] : []

    content {
      datastore_id      = "local-zfs"
      interface         = "ide0"
      user_data_file_id = proxmox_virtual_environment_file.kimbap[each.key].id

      ip_config {
        ipv4 {
          address = each.value.network.ipv4 == "dhcp" ? each.value.network.ipv4 : each.value.network.ipv4.address
          gateway = each.value.network.ipv4 == "dhcp" ? null : each.value.network.ipv4.gateway
        }
        ipv6 {
          address = each.value.network.ipv6 == "dhcp" ? each.value.network.ipv6 : each.value.network.ipv6.address
          gateway = each.value.network.ipv6 == "dhcp" ? null : each.value.network.ipv6.gateway
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      initialization
    ]
  }
}
