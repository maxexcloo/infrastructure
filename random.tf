resource "random_password" "b2_bucket_server" {
  for_each = local.servers_merged

  length  = 6
  special = false
  upper   = false
}

resource "random_password" "b2_bucket_website" {
  for_each = {
    for k, website in local.websites : k => website
    if website.enable_b2_bucket
  }

  length  = 6
  special = false
  upper   = false
}

resource "random_password" "cloudflare_tunnel" {
  for_each = local.servers_merged

  length  = 32
  special = false
}

resource "random_password" "database_password" {
  for_each = {
    for k, website in local.websites : k => website
    if website.enable_database_password
  }

  length  = 24
  special = false
}

resource "random_password" "secret_hash" {
  for_each = {
    for k, website in local.websites : k => website
    if website.enable_secret_hash
  }

  length  = 32
  special = false
}

resource "random_password" "server" {
  for_each = local.servers_merged

  length  = 24
  special = false
}

resource "random_password" "website" {
  for_each = {
    for k, website in local.websites : k => website
    if website.enable_password
  }

  length  = 24
  special = false
}
