resource "ssh_resource" "mac" {
  for_each = local.mac_servers_merged

  agent = true
  host  = each.value.config.parent_host
  user  = each.value.config.parent_user
  when  = "create"

  commands = [
    "cd ${each.value.config.parent_path} && /opt/homebrew/bin/mkisofs -joliet -output ${each.value.name}.iso -rock -volid cidata meta-data user-data",
    "cd ${each.value.config.parent_path} && /usr/local/bin/vagrant up --machine-readable --provision"
  ]

  pre_commands = [
    "mkdir -p ${each.value.config.parent_path}",
    "touch ${each.value.config.parent_path}/meta-data"
  ]

  file {
    content     = templatefile("./templates/mac/vagrantfile.tftpl", each.value)
    destination = "${each.value.config.parent_path}/Vagrantfile"
  }

  file {
    content     = local.cloud_init_mac[each.key]
    destination = "${each.value.config.parent_path}/user-data"
  }
}

resource "ssh_resource" "mac-destroy" {
  for_each = local.mac_servers_merged

  agent = true
  host  = each.value.config.parent_host
  user  = each.value.config.parent_user
  when  = "destroy"

  commands = [
    "cd ${each.value.config.parent_path} && /usr/local/bin/vagrant destroy --force",
    "rm -rf ${each.value.config.parent_path}"
  ]
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
