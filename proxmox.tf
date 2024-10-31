resource "proxmox_virtual_environment_download_file" "vm" {
  for_each = {
    for k, vm in local.merged_vms_proxmox : k => vm
    if vm.config.boot_disk_image_url != ""
  }

  content_type   = "iso"
  datastore_id   = "local"
  file_name      = "${each.value.name}${endswith(each.value.config.boot_disk_image_url, ".iso") ? ".iso" : ".img"}"
  node_name      = each.value.parent
  overwrite      = false
  upload_timeout = 1800
  url            = each.value.config.boot_disk_image_url
}

resource "proxmox_virtual_environment_file" "vm" {
  for_each = {
    for k, vm in local.merged_vms_proxmox : k => vm
    if endswith(vm.config.boot_disk_image_url, ".img")
  }

  content_type = "snippets"
  datastore_id = "local"
  node_name    = each.value.parent

  source_raw {
    file_name = "${each.value.name}.yaml"

    data = templatefile(
      "templates/cloud_config/cloud_config.tftpl",
      {
        cloudflare_tunnel_token = local.output_cloudflare_tunnel_tokens[each.key]
        password                = htpasswd_password.server[each.key].sha512
        server                  = each.value
        ssh_keys                = concat(data.github_user.default.ssh_keys, [local.output_ssh[each.key].public_key])
        tailscale_tailnet_key   = local.output_tailscale_tailnet_keys[each.key]
      }
    )
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = local.merged_vms_proxmox

  bios          = "ovmf"
  machine       = "q35"
  name          = each.value.name
  node_name     = each.value.parent
  scsi_hardware = "virtio-scsi-single"

  cpu {
    cores = each.value.config.cpus
    type  = "host"
  }

  disk {
    backup       = true
    datastore_id = "local-zfs"
    discard      = "on"
    file_format  = "raw"
    file_id      = endswith(each.value.config.boot_disk_image_url, ".img") ? proxmox_virtual_environment_download_file.vm[each.key].id : null
    interface    = "virtio0"
    iothread     = true
    size         = each.value.config.boot_disk_size
  }

  efi_disk {
    datastore_id = "local-zfs"
    type         = "4m"
  }

  lifecycle {
    ignore_changes = [
      initialization
    ]
  }

  memory {
    dedicated = each.value.config.memory * 1024
    floating  = 0
  }

  operating_system {
    type = each.value.config.operating_system
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
      file_id   = proxmox_virtual_environment_download_file.vm[each.key].id
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

  dynamic "hostpci" {
    for_each = each.value.hostpci

    content {
      device = "hostpci${hostpci.key}"
      id     = hostpci.value.id
      pcie   = try(hostpci.value.pcie, true)
      rombar = true
      xvga   = try(hostpci.value.xvga, false)
    }
  }

  dynamic "initialization" {
    for_each = endswith(each.value.config.boot_disk_image_url, ".img") ? [true] : []

    content {
      datastore_id      = "local-zfs"
      interface         = "ide0"
      user_data_file_id = proxmox_virtual_environment_file.vm[each.key].id

      ip_config {
        ipv4 {
          address = "dhcp"
        }
        ipv6 {
          address = "dhcp"
        }
      }
    }
  }

  dynamic "network_device" {
    for_each = try(each.value.config.disable_network, false) ? [] : [true]

    content {
      firewall = true
    }
  }

  dynamic "usb" {
    for_each = each.value.usb

    content {
      host = usb.value.host
      usb3 = try(usb.value.usb3, true)
    }
  }
}
