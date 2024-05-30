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
        target = [for k, tag in local.tags : tag.tailscale_tag]
      }
    ],
    tagOwners = {
      for k, tag in local.tags : tag.tailscale_tag => [var.default.email]
    }
  })
}

resource "tailscale_tailnet_key" "server" {
  for_each = local.servers_merged

  description   = "${each.value.tags[0]}-${each.key}"
  preauthorized = true
  reusable      = true
  tags          = [local.tags[each.value.tags[0]].tailscale_tag]

  depends_on = [
    tailscale_acl.default
  ]
}

resource "tailscale_tailnet_key" "website" {
  for_each = {
    for k, website in local.websites : k => website
    if website.tailscale_key
  }

  description   = "ephemeral-${each.value.app_name}"
  ephemeral     = true
  preauthorized = true
  reusable      = true
  tags          = [local.tags["ephemeral"].tailscale_tag]

  depends_on = [
    tailscale_acl.default
  ]
}
