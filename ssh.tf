resource "ssh_resource" "router" {
  for_each = local.merged_routers

  agent = true
  host  = each.key
  port  = each.value.network.ssh_port
  user  = each.value.user.username

  commands = [
    "/etc/init.d/dropbear restart"
  ]

  file {
    content     = "${join("\n", concat([trimspace(tls_private_key.server_ssh_key[each.key].public_key_openssh)], each.value.user.ssh_keys))}\n"
    destination = "/etc/dropbear/authorized_keys"
  }
}
