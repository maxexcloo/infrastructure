data "onepassword_vault" "infrastructure" {
  name = var.terraform.onepassword.vault
}

resource "onepassword_item" "server" {
  for_each = local.filtered_servers_all

  category = "login"
  password = random_password.server[each.key].result
  title    = each.key
  url      = each.value.fqdn_internal
  username = each.value.user.username
  vault    = data.onepassword_vault.infrastructure.uuid
}
