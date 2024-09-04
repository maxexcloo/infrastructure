resource "ssh_resource" "router" {
  for_each = local.merged_routers

  agent = true
  host  = each.key
  port  = each.value.network.ssh_port
  user  = each.value.user.username

  commands = [
    "touch /etc/haproxy.infrastructure.cfg /etc/haproxy.services.cfg",
    "cat /etc/haproxy.infrastructure.cfg /etc/haproxy.services.cfg > /etc/haproxy.cfg",
    "/etc/init.d/dropbear restart",
    "/etc/init.d/haproxy restart"
  ]

  file {
    content     = "${join("\n", concat(data.github_user.default.ssh_keys, [local.output_ssh[each.key].public_key]))}\n"
    destination = "/etc/dropbear/authorized_keys"
  }

  file {
    destination = "/etc/haproxy.infrastructure.cfg"

    content = templatefile(
      "./templates/openwrt/haproxy.infrastructure.cfg.tftpl",
      {
        servers = {
          for k, v in local.filtered_servers_noncloud : k => v
          if k != each.key && v.location == each.value.location && v.network.private_address != ""
        }
      }
    )
  }
}
