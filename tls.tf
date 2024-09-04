resource "tls_private_key" "ssh_key_server" {
  for_each = local.filtered_servers_all

  algorithm = "ED25519"
}
