data "onepassword_vault" "infrastructure" {
  name = var.terraform.onepassword.vault
}

resource "onepassword_item" "server" {
  for_each = local.servers

  category = "login"
  password = random_password.server[each.key].result
  title    = each.key
  username = each.value.user.username
  vault    = data.onepassword_vault.infrastructure.uuid

  section {
    label = "websites"

    field {
      label = "fqdn"
      type  = "URL"
      value = each.value.fqdn
    }

    field {
      label = "host"
      type  = "URL"
      value = each.value.host
    }

    dynamic "field" {
      for_each = try(each.value.network.private_address, "") != "" ? [true] : []

      content {
        label = "private"
        type  = "URL"
        value = each.value.network.private_address
      }
    }
  }
}

resource "onepassword_item" "website" {
  for_each = { for k, v in local.websites : k => v if try(v.username, "") != "" }

  category = "login"
  password = random_password.website[each.key].result
  title    = cloudflare_record.website[each.key].hostname
  url      = cloudflare_record.website[each.key].hostname
  username = each.value.username
  vault    = data.onepassword_vault.infrastructure.uuid
}
