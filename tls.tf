resource "tls_private_key" "server" {
  for_each = local.servers_merged

  algorithm = "ED25519"
}
