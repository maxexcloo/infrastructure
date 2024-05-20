resource "macaddress" "config" {
  for_each = { for k, v in local.servers : k => v if v.parent_type == "mac" }

  prefix = [0, 28, 66]
}
