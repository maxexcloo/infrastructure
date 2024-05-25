resource "openwrt_dhcp_host" "au" {
  for_each = {
    for k, v in local.servers_merged : k => v
    if v.location == "au" && try(proxmox_virtual_environment_vm.gen8[k].mac_addresses[0], v.network.mac_address, "") != ""
  }

  id       = replace(each.value.name, "-", "")
  ip       = each.value.network.private_address
  mac      = try(proxmox_virtual_environment_vm.gen8[each.key].mac_addresses[0], each.value.network.mac_address)
  name     = each.value.name
  provider = openwrt.au
}

# resource "openwrt_dhcp_host" "kr" {
#   for_each = {
#     for k, v in local.servers_merged : k => v
#     if v.location == "kr" && try(proxmox_virtual_environment_vm.kimbap[k].mac_addresses[0], v.network.mac_address, "") != ""
#   }

#   id       = replace(each.value.name, "-", "")
#   ip       = each.value.network.private_address
#   mac      = try(proxmox_virtual_environment_vm.kimbap[each.key].mac_addresses[0], each.value.network.mac_address)
#   name     = each.value.name
#   provider = openwrt.kr
# }
