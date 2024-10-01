# resource "openwrt_dhcp_host" "au" {
#   for_each = {
#     for k, server in local.filtered_servers_openwrt : k => server
#     if server.location == "au"
#   }

#   id       = replace(each.value.name, "-", "")
#   ip       = each.value.network.private_address
#   mac      = try(proxmox_virtual_environment_vm.vm[each.key].network_device[0].mac_address, each.value.network.mac_address)
#   name     = each.value.name
#   provider = openwrt.au

#   depends_on = [
#     proxmox_virtual_environment_vm.vm
#   ]
# }

# resource "openwrt_dhcp_host" "kr" {
#   for_each = {
#     for k, server in local.filtered_servers_openwrt : k => server
#     if server.location == "kr"
#   }

#   id       = replace(each.value.name, "-", "")
#   ip       = each.value.network.private_address
#   mac      = try(proxmox_virtual_environment_vm.vm[each.key].network_device[0].mac_address, each.value.network.mac_address)
#   name     = each.value.name
#   provider = openwrt.kr

#   depends_on = [
#     proxmox_virtual_environment_vm.vm
#   ]
# }
