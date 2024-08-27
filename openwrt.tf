resource "openwrt_dhcp_host" "au" {
  for_each = {
    for k, v in local.filtered_servers_all : k => v
    if v.location == "au" && (v.parent_type == "proxmox" || try(v.network.mac_address, "") != "")
  }

  id       = replace(each.value.name, "-", "")
  ip       = each.value.network.private_address
  mac      = try(proxmox_virtual_environment_vm.gen8[each.key].network_device[0].mac_address, each.value.network.mac_address)
  name     = each.value.name
  provider = openwrt.au

  depends_on = [
    proxmox_virtual_environment_vm.gen8
  ]
}

resource "openwrt_dhcp_host" "kr" {
  for_each = {
    for k, v in local.filtered_servers_all : k => v
    if v.location == "kr" && (v.parent_type == "proxmox" || try(v.network.mac_address, "") != "")
  }

  id       = replace(each.value.name, "-", "")
  ip       = each.value.network.private_address
  mac      = try(proxmox_virtual_environment_vm.kimbap[each.key].network_device[0].mac_address, each.value.network.mac_address)
  name     = each.value.name
  provider = openwrt.kr

  depends_on = [
    proxmox_virtual_environment_vm.kimbap
  ]
}
