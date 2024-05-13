resource "proxmox_virtual_environment_download_file" "gen8" {
  for_each = {
    for i, virtual_machine in var.virtual_machines : "${virtual_machine.hostname}.${virtual_machine.location}.${var.root_domain}" => virtual_machine
    if virtual_machine.disk_url != "" && virtual_machine.parent == "gen8"
  }

  content_type        = "iso"
  datastore_id        = "local"
  node_name           = each.value.parent
  overwrite_unmanaged = true
  provider            = proxmox.gen8
  url                 = each.value.disk_url
}

resource "proxmox_virtual_environment_download_file" "kimbap" {
  for_each = {
    for i, virtual_machine in var.virtual_machines : "${virtual_machine.hostname}.${virtual_machine.location}.${var.root_domain}" => virtual_machine
    if virtual_machine.disk_url != "" && virtual_machine.parent == "kimbap"
  }

  content_type        = "iso"
  datastore_id        = "local"
  node_name           = each.value.parent
  overwrite_unmanaged = true
  provider            = proxmox.kimbap
  url                 = each.value.disk_url
}

resource "proxmox_virtual_environment_vm" "gen8" {
  for_each = {
    for i, virtual_machine in var.virtual_machines : "${virtual_machine.hostname}.${virtual_machine.location}.${var.root_domain}" => virtual_machine
    if virtual_machine.parent == "gen8"
  }

  bios          = "ovmf"
  machine       = "q35"
  name          = each.value.hostname
  node_name     = each.value.parent
  provider      = proxmox.gen8
  scsi_hardware = "virtio-scsi-single"

  cpu {
    cores = each.value.config.cpus
    type  = "x86-64-v2-AES"
  }

  disk {
    datastore_id = "local-zfs"
    discard      = "on"
    file_format  = "raw"
    file_id      = endswith(each.value.disk_url, ".img") ? proxmox_virtual_environment_download_file.gen8[each.key].id : null
    interface    = "virtio0"
    iothread     = true
    size         = each.value.config.disk_size
  }

  efi_disk {
    datastore_id = "local-zfs"
    type         = "4m"
  }

  memory {
    dedicated = each.value.config.memory * 1024
    floating  = each.value.config.memory * 1024
  }

  network_device {
    firewall = true
  }

  operating_system {
    type = each.value.config.operating_system
  }

  dynamic "cdrom" {
    for_each = endswith(each.value.disk_url, ".iso") ? [true] : []

    content {
      enabled   = true
      file_id   = proxmox_virtual_environment_download_file.gen8[each.key].id
      interface = "ide0"
    }
  }

  # dynamic "disk" {
  #   for_each = try(each.value.physical_disks, [])

  #   content {
  #     backup            = false
  #     datastore_id      = ""
  #     interface         = disk.key
  #     path_in_datastore = disk.value
  #     replicate         = false
  #   }
  # }

  dynamic "initialization" {
    for_each = endswith(each.value.disk_url, ".img") ? [true] : []

    content {
      datastore_id = "local-zfs"
      interface    = "ide0"
      upgrade      = true

      dns {
        domain  = "${each.value.location}.${var.root_domain}"
        servers = ["192.168.0.1"]
      }

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

      user_account {
        keys     = data.github_user.config.ssh_keys
        username = each.value.username
      }
    }
  }
}


resource "proxmox_virtual_environment_vm" "kimbap" {
  for_each = {
    for i, virtual_machine in var.virtual_machines : "${virtual_machine.hostname}.${virtual_machine.location}.${var.root_domain}" => virtual_machine
    if virtual_machine.parent == "kimbap"
  }

  bios          = "ovmf"
  machine       = "q35"
  name          = each.value.hostname
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
    file_id      = endswith(each.value.disk_url, ".img") ? proxmox_virtual_environment_download_file.kimbap[each.key].id : null
    interface    = "virtio0"
    iothread     = true
    size         = each.value.config.disk_size
  }

  efi_disk {
    datastore_id = "local-zfs"
    type         = "4m"
  }

  memory {
    dedicated = each.value.config.memory * 1024
    floating  = each.value.config.memory * 1024
  }

  network_device {
    firewall = true
  }

  operating_system {
    type = each.value.config.operating_system
  }

  dynamic "cdrom" {
    for_each = endswith(each.value.disk_url, ".iso") ? [true] : []

    content {
      enabled   = true
      file_id   = proxmox_virtual_environment_download_file.kimbap[each.key].id
      interface = "ide0"
    }
  }

  # dynamic "disk" {
  #   for_each = try(each.value.physical_disks, [])

  #   content {
  #     backup            = false
  #     datastore_id      = ""
  #     interface         = disk.key
  #     path_in_datastore = disk.value
  #     replicate         = false
  #   }
  # }

  dynamic "initialization" {
    for_each = endswith(each.value.disk_url, ".img") ? [true] : []

    content {
      datastore_id = "local-zfs"
      interface    = "ide0"
      upgrade      = true

      dns {
        domain  = "${each.value.location}.${var.root_domain}"
        servers = ["192.168.0.1"]
      }

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

      user_account {
        keys     = data.github_user.config.ssh_keys
        username = each.value.username
      }
    }
  }
}
