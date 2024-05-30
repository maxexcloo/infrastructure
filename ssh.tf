resource "ssh_resource" "router" {
  for_each = {
    for k, v in local.routers : k => v
    if v.name == "au"
  }

  agent = true
  host  = each.key
  port  = each.value.network.ssh_port
  user  = each.value.user.username

  commands = [
    "/etc/rc.d/S19dropbear restart",
    "/etc/rc.d/S99haproxy restart"
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
          for k, v in local.servers_merged_cloudflare : k => v
          if k != each.key && v.location == each.value.location && v.network.private_address != ""
        }
        websites = {
          for k, v in local.websites_merged_openwrt : k => v
          if k != each.value.location && v.location == each.value.location
        }
      }
    )
  }
}

resource "ssh_resource" "server" {
  for_each = local.servers_merged_ssh

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

resource "ssh_resource" "vm_mac" {
  for_each = local.vms_mac
  when     = "create"

  agent = true
  host  = each.value.provider.host
  port  = each.value.provider.port
  user  = each.value.provider.username

  commands = [
    "cd ${each.value.provider.path} && ${each.value.provider.mkisofs_path} -joliet -output ${each.value.name}.iso -rock -volid cidata meta-data user-data",
    "cd ${each.value.provider.path} && ${each.value.provider.vagrant_path} up --machine-readable --provision"
  ]

  pre_commands = [
    "mkdir -p ${each.value.provider.path}",
    "touch ${each.value.provider.path}/meta-data"
  ]

  file {
    content     = templatefile("./templates/mac/vagrantfile.tftpl", each.value)
    destination = "${each.value.provider.path}/Vagrantfile"
  }

  file {
    destination = "${each.value.provider.path}/user-data"

    content = templatefile(
      "./templates/cloud_config.tftpl",
      {
        password      = htpasswd_password.server[each.key].sha512
        server        = each.value
        ssh_key       = trimspace(tls_private_key.server_ssh_key[each.key].public_key_openssh)
        tailscale_key = tailscale_tailnet_key.server[each.key].key
      }
    )
  }
}

resource "ssh_resource" "vm_mac-destroy" {
  for_each = local.vms_mac
  when     = "destroy"

  agent = true
  host  = each.value.provider.host
  port  = each.value.provider.port
  user  = each.value.provider.username

  commands = [
    "cd ${each.value.provider.path} && ${each.value.provider.vagrant_path} destroy --force",
    "rm -rf ${each.value.provider.path}"
  ]
}
