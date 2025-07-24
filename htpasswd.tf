resource "htpasswd_password" "server" {
  for_each = local.servers_filtered_all

  password = onepassword_item.server[each.key].password
}
