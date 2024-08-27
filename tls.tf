resource "tls_private_key" "server_ssh_key" {
  for_each = local.filtered_servers_all

  algorithm = "ED25519"
}
