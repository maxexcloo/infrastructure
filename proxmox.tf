resource "proxmox_virtual_environment_download_file" "vm" {
  for_each = {
    for k, vm in local.merged_vms_proxmox : k => vm
    if vm.config.boot_disk_image_url != ""
  }

  content_type            = "iso"
  datastore_id            = "local"
  decompression_algorithm = each.value.config.boot_disk_image_compression_algorithm
  file_name               = "${each.value.name}${endswith(each.value.config.boot_disk_image_url, ".iso") ? ".iso" : ".img"}"
  node_name               = each.value.parent
  overwrite               = false
  upload_timeout          = 1800
  url                     = each.value.config.boot_disk_image_url
}

resource "proxmox_virtual_environment_file" "vm" {
  for_each = {
    for k, vm in local.merged_vms_proxmox : k => vm
    if !endswith(vm.config.boot_disk_image_url, ".iso")
  }

  content_type = "snippets"
  datastore_id = "local"
  node_name    = each.value.parent

  source_raw {
    file_name = "${each.value.name}.yaml"

    data = templatefile(
      "templates/cloud_config/cloud_config.tftpl",
      {
        cloudflare_tunnel_token = try(local.output_cloudflare_tunnels[each.key].token, "")
        default                 = var.default
        k                       = each.key
        password                = htpasswd_password.server[each.key].sha512
        server                  = each.value
        ssh_keys                = concat(data.github_user.default.ssh_keys, [local.output_ssh[each.key].public_key])
        tailscale_tailnet_key   = try(local.output_tailscale_tailnet_keys[each.key], "")
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
    file_id      = endswith(each.value.config.boot_disk_image_url, ".iso") ? null : proxmox_virtual_environment_download_file.vm[each.key].id
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
    for_each = endswith(each.value.config.boot_disk_image_url, ".iso") ? [] : [true]

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

  dynamic "hostpci" {
    for_each = each.value.hostpci

    content {
      device = "hostpci${hostpci.key}"
      id     = hostpci.value.id
      pcie   = hostpci.value.pcie
      rombar = true
      xvga   = hostpci.value.xvga
    }
  }

  dynamic "initialization" {
    for_each = endswith(each.value.config.boot_disk_image_url, ".iso") ? [] : [true]

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
    for_each = each.value.networks

    content {
      enabled     = network_device.value.enabled
      firewall    = network_device.value.firewall
      mac_address = network_device.value.mac_address
      vlan_id     = network_device.value.vlan_id
    }
  }

  dynamic "usb" {
    for_each = each.value.usb

    content {
      host = usb.value.host
      usb3 = usb.value.usb3
    }
  }
}
