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
      exitNode = local.merged_tags_tailscale
      routes = {
        "0.0.0.0/0" = local.merged_tags_tailscale
        "::/0"      = local.merged_tags_tailscale
      }
    }
    tagOwners = {
      for tag in local.merged_tags_tailscale : tag => [var.default.email]
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
  tags          = ["tag:${each.value.tag}"]

  depends_on = [
    tailscale_acl.default
  ]
}
