resource "ssh_resource" "mac" {
  for_each = { for k, v in local.servers : k => v if v.type == "mac" }

  agent = true
  host  = each.value.host
  user  = each.value.user.username

  commands = [
    "bash -l ${each.value.config.parallels_path}/vagrant.sh"
  ]

  file {
    destination = "${each.value.config.parallels_path}/vagrant.sh"

    content = templatefile(
      "./templates/mac/vagrant.sh.tftpl",
      {
        parallels_path = each.value.config.parallels_path
        servers        = { for k, v in local.mac_servers : k => v if v.parent_name == each.value.name }
      }
    )
  }

  file {
    destination = "${each.value.config.parallels_path}/Vagrantfile"

    content = templatefile(
      "./templates/mac/vagrantfile.tftpl",
      {
        parallels_path = each.value.config.parallels_path
        servers        = { for k, v in local.mac_servers : k => v if v.parent_name == each.value.name }
      }
    )
  }

  dynamic "file" {
    for_each = { for k, v in local.servers : k => v if v.parent_name == each.value.name }

    content {
      content     = local.cloud_init_mac[file.key]
      destination = "${each.value.config.parallels_path}/${file.value.name}.yaml"
    }
  }
}

resource "ssh_resource" "openwrt" {
  for_each = { for k, v in local.servers : k => v if v.location == "au" && v.type == "openwrt" }

  agent = true
  host  = each.value.host
  user  = each.value.user.username

  commands = [
    "/etc/rc.d/S99haproxy restart"
  ]

  file {
    destination = "/etc/haproxy.cfg"

    content = trimsuffix(
      templatefile(
        "./templates/openwrt/haproxy.cfg.tftpl",
        {
          servers = {
            for k, v in local.servers : k => v
            if v.host != each.value.host && v.location == each.value.location && try(v.network.private_address, "") != ""
          }
          websites = {
            for k, v in local.openwrt_websites_merged : k => v
            if v.host != each.value.location && v.location == each.value.location
          }
        }
      ),
      "\n"
    )
  }
}
