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
        "::/0"      = [for k, tag in local.merged_tags : tag.tailscale_tag]
        "0.0.0.0/0" = [for k, tag in local.merged_tags : tag.tailscale_tag]
      }
    }
    nodeAttrs = [
      {
        attr   = ["nextdns:65188d"]
        target = [for k, tag in local.merged_tags : tag.tailscale_tag]
      }
    ]
    tagOwners = {
      for k, tag in local.merged_tags : tag.tailscale_tag => [var.default.email]
    }
  })
}

resource "tailscale_tailnet_key" "server" {
  for_each = local.filtered_servers_all

  description   = "${each.value.tag}-${each.key}"
  preauthorized = true
  reusable      = true
  tags          = [local.merged_tags[each.value.tag].tailscale_tag]

  depends_on = [
    tailscale_acl.default
  ]
}
