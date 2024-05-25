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

# openwrt_websites_merged = merge([
#   for i, website in local.cloudflare_records_merged : {
#     for k, server in local.servers : i => {
#       fqdn     = website.hostname
#       host     = server.host
#       location = server.location
#     }
#     if(server.fqdn == website.hostname || server.fqdn == website.value) && server.parent_type != "cloud" && server.tag != "router"
#   }
# ]...)

# resource "ssh_resource" "router" {
#   for_each = local.routers

#   agent = true
#   host  = each.value.host
#   port  = each.value.network.ssh_port
#   user  = each.value.user.username

#   commands = [
#     "/etc/rc.d/S99haproxy restart"
#   ]

#   file {
#     destination = "/etc/haproxy.cfg"

#     content = trim(
#       templatefile(
#         "./templates/openwrt/haproxy.cfg.tftpl",
#         {
#           servers = {
#             for k, v in local.servers : k => v
#             if v.host != each.value.host && v.location == each.value.location && try(v.network.private_address, "") != ""
#           }
#           websites = {
#             for k, v in local.openwrt_websites_merged : k => v
#             if v.host != each.value.location && v.location == each.value.location
#           }
#         }
#       ),
#       "\n"
#     )
#   }
# }
