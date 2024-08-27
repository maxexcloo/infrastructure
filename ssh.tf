resource "ssh_resource" "router" {
  for_each = local.merged_routers

  agent = true
  host  = each.key
  port  = each.value.network.ssh_port
  user  = each.value.user.username

  commands = [
    "/etc/init.d/dropbear restart",
    "/etc/init.d/haproxy restart"
  ]

  file {
    content     = "${join("\n", concat([trimspace(tls_private_key.server_ssh_key[each.key].public_key_openssh)], each.value.user.ssh_keys))}\n"
    destination = "/etc/dropbear/authorized_keys"
  }

  file {
    destination = "/etc/haproxy.cfg"

    content = templatefile(
      "./templates/openwrt/haproxy.cfg.tftpl",
      {
        servers = {
          for k, v in local.filtered_servers_noncloud : k => v
          if k != each.key && v.location == each.value.location && v.network.private_address != ""
        }
        websites = {
          for k, v in local.filtered_websites_noncloud : k => v
          if k != each.value.location && v.location == each.value.location
        }
      }
    )
  }
}

resource "ssh_resource" "server" {
  for_each = local.filtered_servers_ssh

  agent = true
  host  = each.key
  port  = each.value.network.ssh_port
  user  = each.value.user.username

  commands = [
    "mkdir -p ~/.ssh"
  ]

  file {
    content     = "${join("\n", concat([trimspace(tls_private_key.server_ssh_key[each.key].public_key_openssh)], each.value.user.ssh_keys))}\n"
    destination = "~/.ssh/authorized_keys"
  }
}
