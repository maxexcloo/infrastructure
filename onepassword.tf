data "onepassword_vault" "infrastructure" {
  name = var.terraform.onepassword.vault
}

resource "onepassword_item" "server" {
  for_each = local.servers_merged

  category = "login"
  password = random_password.server[each.key].result
  title    = each.key
  url      = "${each.value.name}.${var.default.domain_internal}"
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
  url      = "${each.value.ssl ? "${each.value.port != 0 ? "https://" : ""}" : "http://"}${each.value.fqdn}${each.value.port != 0 ? ":${each.value.port}" : ""}"
  username = each.value.username
  vault    = data.onepassword_vault.infrastructure.uuid

  lifecycle {
    ignore_changes = [
      section
    ]
  }
}
