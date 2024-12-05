resource "tls_private_key" "ssh_key" {
  for_each = local.filtered_servers.all

  algorithm = "ED25519"
}
