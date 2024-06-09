data "onepassword_vault" "infrastructure" {
  name = var.terraform.onepassword.vault
}

resource "onepassword_item" "server" {
  for_each = local.servers_merged

  category = "login"
  password = random_password.server[each.key].result
  title    = each.key
  url      = each.value.fqdn_internal
  username = each.value.user.username
  vault    = data.onepassword_vault.infrastructure.uuid

  lifecycle {
    ignore_changes = [
      section
    ]
  }
}

resource "onepassword_item" "website" {
  for_each = {
    for k, website in local.websites : k => website
    if website.enable_password || website.username != ""
  }

  category = "login"
  password = each.value.enable_password ? random_password.website[each.key].result : null
  title    = each.value.description
  url      = each.value.onepassword_url
  username = each.value.username != "" ? each.value.username : null
  vault    = data.onepassword_vault.infrastructure.uuid

  lifecycle {
    ignore_changes = [
      section
    ]
  }
}
