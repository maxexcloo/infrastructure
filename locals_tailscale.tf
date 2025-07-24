locals {
  filtered_tailscale_devices = {
    for k, server in local.filtered_servers_all : k => {
      fqdn_external = server.fqdn_external
      fqdn_internal = server.fqdn_internal
      private_ipv4  = element([for device in data.tailscale_devices.default.devices : element([for address in device.addresses : address if can(cidrhost("${address}/32", 0))], 0) if element(split(".", device.name), 0) == k], 0)
      private_ipv6  = element([for device in data.tailscale_devices.default.devices : element([for address in device.addresses : address if can(cidrhost("${address}/128", 0))], 0) if element(split(".", device.name), 0) == k], 0)
    }
    if length([for device in data.tailscale_devices.default.devices : device if element(split(".", device.name), 0) == k]) > 0
  }

  merged_tags_tailscale = [
    for tag in var.tags : "tag:${tag}"
  ]
}