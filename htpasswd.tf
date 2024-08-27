resource "htpasswd_password" "server" {
  for_each = local.filtered_servers_all

  password = random_password.server[each.key].result
}
