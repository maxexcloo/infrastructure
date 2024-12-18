data "tailscale_devices" "default" {}

resource "tailscale_acl" "default" {
  acl = jsonencode({
    acls = [
      {
        action = "accept"
        ports  = ["*:*"]
        users  = ["*"]
      }
    ]
    autoApprovers = {
      exitNode = [for tag in local.merged_tags : tag.tailscale_tag]
      routes = {
        "0.0.0.0/0" = [for tag in local.merged_tags : tag.tailscale_tag]
        "::/0"      = [for tag in local.merged_tags : tag.tailscale_tag]
      }
    }
    tagOwners = {
      for k, tag in local.merged_tags : tag.tailscale_tag => [var.default.email]
    }
  })
}

resource "tailscale_tailnet_key" "server" {
  for_each = {
    for k, server in local.filtered_servers_all : k => server
    if contains(server.flags, "tailscale")
  }

  description   = "${each.value.tag}-${each.key}"
  preauthorized = true
  reusable      = true
  tags          = [local.merged_tags[each.value.tag].tailscale_tag]

  depends_on = [
    tailscale_acl.default
  ]
}
