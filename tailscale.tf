data "tailscale_devices" "config" {}

resource "tailscale_acl" "config" {
  acl = jsonencode({
    acls = [
      {
        action = "accept"
        ports  = ["*:*"]
        users  = ["*"]
      }
    ],
    nodeAttrs = [
      {
        attr   = ["nextdns:65188d"]
        target = ["tag:router", "tag:server"]
      }
    ],
    tagOwners = {
      "tag:router" = [var.root.email]
      "tag:server" = [var.root.email]
    }
  })
}

resource "tailscale_device_key" "config" {
  for_each = {
    for i, device in data.tailscale_devices.config.devices : device.name => device
  }

  device_id           = each.value.id
  key_expiry_disabled = true
}

resource "tailscale_device_subnet_routes" "config" {
  for_each = {
    for i, device in data.tailscale_devices.config.devices : device.name => device
    if length(device.tags) > 0
  }

  device_id = each.value.id

  routes = [
    "0.0.0.0/0",
    "::/0"
  ]
}

resource "tailscale_tailnet_key" "router" {
  for_each = local.merged_routers

  description   = each.value.location
  preauthorized = true
  reusable      = true
  tags          = ["tag:router"]
}

resource "tailscale_tailnet_key" "server" {
  for_each = local.merged_servers

  description   = "${each.value.location}-${each.value.hostname}"
  preauthorized = true
  reusable      = true
  tags          = ["tag:server"]
}
