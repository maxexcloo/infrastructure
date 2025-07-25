locals {
  tailscale_devices = {
    for k, server in local.servers : k => {
      fqdn_external = server.fqdn_external
      fqdn_internal = server.fqdn_internal
      private_ipv4  = [for device in data.tailscale_devices.default.devices : [for address in device.addresses : address if can(cidrhost("${address}/32", 0))][0] if split(".", device.name)[0] == k][0]
      private_ipv6  = [for device in data.tailscale_devices.default.devices : [for address in device.addresses : address if can(cidrhost("${address}/128", 0))][0] if split(".", device.name)[0] == k][0]
    }
    if length([for device in data.tailscale_devices.default.devices : device if split(".", device.name)[0] == k]) > 0
  }

  tailscale_tags = [
    for tag in var.tags : "tag:${tag}"
  ]
}
