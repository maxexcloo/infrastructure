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
        target = [for i, tag in local.merged_tags : "tag:${tag}"]
      }
    ],
    tagOwners = {
      for i, tag in local.merged_tags : "tag:${tag}" => [var.root.email]
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
    if contains(device.tags, "tag:router") || contains(device.tags, "tag:server")
  }

  device_id = each.value.id

  routes = [
    "0.0.0.0/0",
    "::/0"
  ]
}

resource "tailscale_tailnet_key" "config" {
  for_each = local.merged_hosts

  description   = each.value.hostname
  preauthorized = true
  reusable      = true
  tags          = ["tag:${each.value.tag}"]
}
