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
      routes = {
        "::/0"      = local.filtered_tags_tailscale_servers
        "0.0.0.0/0" = local.filtered_tags_tailscale_servers
      }
    }
    nodeAttrs = [
      {
        attr   = ["nextdns:65188d"]
        target = local.filtered_tags_tailscale_servers
      }
    ]
    tagOwners = {
      for k, tag in local.merged_tags_tailscale : tag.tailscale_tag => [var.default.email]
    }
  })
}

resource "tailscale_tailnet_key" "server" {
  for_each = local.filtered_servers_all

  description   = "${each.value.tag}-${each.key}"
  preauthorized = true
  reusable      = true
  tags          = [local.merged_tags_tailscale[each.value.tag].tailscale_tag]

  depends_on = [
    tailscale_acl.default
  ]
}
