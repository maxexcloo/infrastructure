resource "htpasswd_password" "server" {
  for_each = local.filtered_servers_all

  password = onepassword_item.server[each.key].password
}
