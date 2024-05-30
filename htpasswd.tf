resource "htpasswd_password" "server" {
  for_each = local.servers_merged

  password = random_password.server[each.key].result
}
