data "onepassword_vault" "default" {
  name = var.terraform.onepassword.vault
}

resource "onepassword_item" "server" {
  for_each = local.filtered_servers_all

  category = "login"
  title    = each.key
  url      = local.filtered_servers_services[each.key].enable_service ? local.filtered_servers_services[each.key].url : each.key
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
      type  = "CONCEALED"
      value = local.output_b2[each.key].application_key
    }

    field {
      label = "Application Key ID"
      type  = "STRING"
      value = local.output_b2[each.key].application_key_id
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

  dynamic "section" {
    for_each = contains(each.value.flags, "cloudflared") ? [true] : []

    content {
      label = "Cloudflare Tunnel"

      field {
        label = "CNAME"
        type  = "URL"
        value = local.output_cloudflare_tunnels[each.key].cname
      }

      field {
        label = "ID"
        type  = "STRING"
        value = local.output_cloudflare_tunnels[each.key].id
      }

      field {
        label = "Token"
        type  = "CONCEALED"
        value = local.output_cloudflare_tunnels[each.key].token
      }
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

  dynamic "section" {
    for_each = contains(each.value.flags, "tailscale") ? [true] : []

    content {
      label = "Tailscale"

      field {
        label = "Tailnet Key"
        type  = "CONCEALED"
        value = local.output_tailscale_tailnet_keys[each.key]
      }
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
      for_each = can(each.value.network.public_ipv4) ? [true] : []

      content {
        label = "Public IPv4"
        type  = "URL"
        value = each.value.network.public_ipv4
      }
    }

    dynamic "field" {
      for_each = can(each.value.network.public_ipv6) ? [true] : []

      content {
        label = "Public IPv6"
        type  = "URL"
        value = each.value.network.public_ipv6
      }
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
      for_each = local.filtered_servers_services[each.key].enable_service ? [true] : []

      content {
        label = local.filtered_servers_services[each.key].description
        type  = "URL"
        value = local.filtered_servers_services[each.key].url
      }
    }
  }
}
