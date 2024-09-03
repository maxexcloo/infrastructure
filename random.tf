resource "random_password" "b2_bucket_server" {
  for_each = local.filtered_servers_all

  length  = 6
  special = false
  upper   = false
}

resource "random_password" "cloudflare_tunnel" {
  for_each = local.filtered_servers_all

  length  = 32
  special = false
}

resource "random_password" "server" {
  for_each = local.filtered_servers_all

  length  = 24
  special = false
}
