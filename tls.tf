resource "tls_private_key" "server_ssh_key" {
  for_each = local.servers_merged

  algorithm = "ED25519"
}
