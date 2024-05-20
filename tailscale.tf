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
        target = [for i, tag in local.tags : "tag:${tag}"]
      }
    ],
    tagOwners = {
      for i, tag in local.tags : "tag:${tag}" => [var.default.email]
    }
  })
}

resource "tailscale_tailnet_key" "config" {
  for_each = local.servers

  description   = each.value.host
  preauthorized = true
  reusable      = true
  tags          = ["tag:${each.value.tag}"]
}
