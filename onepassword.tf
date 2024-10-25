data "onepassword_vault" "default" {
  name = var.terraform.onepassword.vault
}

resource "onepassword_item" "server" {
  for_each = local.filtered_servers_all

  category = "login"
  title    = each.key
  url      = each.value.network.web_port == 80 && each.value.network.web_ssl == false ? each.value.host : "${each.value.network.web_ssl ? "https://${each.value.fqdn_internal}" : "http://${each.value.host}"}${each.value.network.web_port == 80 ? "" : ":${each.value.network.web_port}"}/"
  username = each.value.user.username
  vault    = data.onepassword_vault.default.uuid

  password_recipe {
    length  = 24
    symbols = false
  }

  section {
    label = "B2"

    field {
      label = "Application Key"
      type  = "STRING"
      value = local.output_b2[each.key].application_key
    }

    field {
      label = "Application Secret"
      type  = "CONCEALED"
      value = local.output_b2[each.key].application_secret
    }

    field {
      label = "Bucket Name"
      type  = "STRING"
      value = local.output_b2[each.key].bucket_name
    }

    field {
      label = "Endpoint"
      type  = "URL"
      value = local.output_b2[each.key].endpoint
    }
  }

  section {
    label = "Cloudflare"

    field {
      label = "Tunnel Token"
      type  = "CONCEALED"
      value = local.output_cloudflare_tunnel_tokens[each.key]
    }
  }

  section {
    label = "Resend"

    field {
      label = "API Key"
      type  = "CONCEALED"
      value = local.output_resend_api_keys[each.key]
    }
  }

  section {
    label = "SSH"

    field {
      label = "Private Key"
      type  = "CONCEALED"
      value = local.output_ssh[each.key].private_key
    }

    field {
      label = "Public Key"
      type  = "STRING"
      value = local.output_ssh[each.key].public_key
    }
  }

  section {
    label = "Secret Hash"

    field {
      label = "Secret Hash"
      type  = "CONCEALED"
      value = local.output_secret_hashes[each.key]
    }
  }

  section {
    label = "Tailscale"

    field {
      label = "Tailnet Key"
      type  = "CONCEALED"
      value = local.output_tailscale_tailnet_keys[each.key]
    }
  }

  section {
    label = "URLs"

    field {
      label = "External FQDN"
      type  = "URL"
      value = each.value.fqdn_external
    }

    field {
      label = "Internal FQDN"
      type  = "URL"
      value = each.value.fqdn_internal
    }

    dynamic "field" {
      for_each = can(each.value.network.public_address) ? [true] : []

      content {
        label = "Public Address"
        type  = "URL"
        value = each.value.network.public_address
      }
    }

    dynamic "field" {
      for_each = can(each.value.network.ipv4) ? [true] : []

      content {
        label = "Public IPv4"
        type  = "URL"
        value = each.value.network.ipv4
      }
    }

    dynamic "field" {
      for_each = can(each.value.network.ipv6) ? [true] : []

      content {
        label = "Public IPv6"
        type  = "URL"
        value = each.value.network.ipv6
      }
    }

    dynamic "field" {
      for_each = each.value.network.private_address != "" ? [true] : []

      content {
        label = "Private Address"
        type  = "URL"
        value = each.value.network.private_address
      }
    }
  }
}
