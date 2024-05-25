resource "macaddress" "server_mac" {
  for_each = { for i, v in var.servers_mac : i => v }

  prefix = [0, 28, 66]
}
