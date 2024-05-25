resource "random_password" "server" {
  for_each = local.servers_merged

  length  = 24
  special = false
}

resource "random_password" "website" {
  for_each = {
    for k, website in local.websites : k => website
    if website.generate_password
  }

  length  = 24
  special = false
}
