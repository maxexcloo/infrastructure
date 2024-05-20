resource "random_password" "server" {
  for_each = local.servers

  length  = 24
  special = false
}

resource "random_password" "website" {
  for_each = { for k, v in local.websites : k => v if try(v.username, "") != "" }

  length  = 24
  special = false
}
