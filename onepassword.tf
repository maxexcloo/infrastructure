data "onepassword_vault" "infrastructure" {
  name = var.terraform.onepassword.vault
}

resource "onepassword_item" "server" {
  for_each = local.servers_merged

  category = "login"
  password = random_password.server[each.key].result
  title    = each.key
  url      = each.key
  username = each.value.user.username
  vault    = data.onepassword_vault.infrastructure.uuid

  lifecycle {
    ignore_changes = [
      section
    ]
  }
}

resource "onepassword_item" "website" {
  for_each = local.websites

  category = "login"
  password = each.value.password ? random_password.website[each.key].result : null
  title    = each.value.description
  url      = cloudflare_record.website[each.key].hostname
  username = each.value.username
  vault    = data.onepassword_vault.infrastructure.uuid

  lifecycle {
    ignore_changes = [
      section
    ]
  }
}
