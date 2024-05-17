resource "htpasswd_password" "server" {
  for_each = random_password.server

  password = each.value.result
}
