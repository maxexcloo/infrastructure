resource "random_password" "b2_server" {
  for_each = local.filtered_servers_all

  length  = 6
  special = false
  upper   = false
}

resource "random_password" "cloudflare_tunnel_server" {
  for_each = local.filtered_servers_all

  length  = 64
  special = false
}

resource "random_password" "secret_hash_server" {
  for_each = local.filtered_servers_all

  length  = 24
  special = false
}
