resource "random_password" "server" {
  for_each = local.servers_merged

  length  = 24
  special = false
}

resource "random_password" "cloudflare_tunnel" {
  for_each = local.servers_merged

  length  = 32
  special = false
}

resource "random_password" "website" {
  for_each = {
    for k, website in local.websites : k => website
    if website.password
  }

  length  = 24
  special = false
}

resource "random_string" "b2_bucket" {
  for_each = local.servers_merged

  length  = 6
  special = false
  upper   = false
}
