resource "tailscale_acl" "default" {
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
        target = [for i, tag in local.tags : "tag:${tag}"]
      }
    ],
    tagOwners = {
      for i, tag in local.tags : "tag:${tag}" => [var.default.email]
    }
  })
}

resource "tailscale_tailnet_key" "server" {
  for_each = local.servers_merged

  description   = each.value.host
  preauthorized = true
  reusable      = true
  tags          = ["tag:${each.value.tag}"]
}
