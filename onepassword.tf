data "onepassword_vault" "infrastructure" {
  name = var.terraform.onepassword.vault
}

resource "onepassword_item" "router" {
  for_each = local.merged_routers

  category = "login"
  password = random_password.router[each.key].result
  title    = each.key
  username = each.value.user.username
  vault    = data.onepassword_vault.infrastructure.uuid

  section {
    label = ""

    field {
      label = "fqdn"
      type  = "URL"
      value = each.key
    }

    field {
      label = "hostname"
      type  = "URL"
      value = each.value.location
    }

    field {
      label = "private address"
      type  = "URL"
      value = each.value.network.private_address
    }
  }
}

resource "onepassword_item" "server" {
  for_each = local.merged_servers

  category = "login"
  password = random_password.server[each.key].result
  title    = each.key
  username = each.value.user.username
  vault    = data.onepassword_vault.infrastructure.uuid

  section {
    label = ""

    field {
      label = "fqdn"
      type  = "URL"
      value = each.key
    }

    field {
      label = "hostname"
      type  = "URL"
      value = "${each.value.location}-${each.value.hostname}"
    }

    dynamic "field" {
      for_each = try(each.value.network.private_address, "") != "" ? [true] : []

      content {
        label = "private address"
        type  = "URL"
        value = each.value.network.private_address
      }
    }
  }
}

resource "onepassword_item" "website" {
  for_each = {
    for k, v in local.merged_websites : k => v
    if try(v.username, "") != ""
  }

  category = "login"
  password = random_password.website[each.key].result
  title    = cloudflare_record.website[each.key].hostname
  url      = cloudflare_record.website[each.key].hostname
  username = each.value.username
  vault    = data.onepassword_vault.infrastructure.uuid
}

resource "random_password" "router" {
  for_each = local.merged_routers

  length  = 24
  special = false
}

resource "random_password" "server" {
  for_each = local.merged_servers

  length  = 24
  special = false
}

resource "random_password" "website" {
  for_each = {
    for k, v in local.merged_websites : k => v
    if try(v.username, "") != ""
  }

  length  = 24
  special = false
}
