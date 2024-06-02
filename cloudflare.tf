data "cloudflare_api_token_permission_groups" "default" {}

resource "cloudflare_account" "default" {
  name = var.terraform.cloudflare.email
}

resource "cloudflare_api_token" "server" {
  for_each = local.servers_merged

  name = each.key

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.default.zone["DNS Write"],
      data.cloudflare_api_token_permission_groups.default.zone["Zone Read"],
    ]
    resources = {
      "com.cloudflare.api.account.zone.${cloudflare_zone.zone[var.default.domain_internal].id}" = "*"
    }
  }
}

resource "cloudflare_record" "dns" {
  for_each = local.dns

  allow_overwrite = true
  name            = each.value.name == "@" ? each.value.zone : each.value.name
  priority        = try(each.value.priority, null)
  type            = each.value.type
  value           = each.value.value
  zone_id         = cloudflare_zone.zone[each.value.zone].id
}

resource "cloudflare_record" "internal_ipv4" {
  for_each = local.servers_merged

  allow_overwrite = true
  name            = each.value.fqdn_internal
  type            = "A"
  value           = try(local.tailscale_devices[each.key].ipv4, "127.0.0.1")
  zone_id         = cloudflare_zone.zone[var.default.domain_internal].id
}

resource "cloudflare_record" "internal_ipv6" {
  for_each = local.servers_merged

  allow_overwrite = true
  name            = each.value.fqdn_internal
  type            = "AAAA"
  value           = try(local.tailscale_devices[each.key].ipv6, "::1")
  zone_id         = cloudflare_zone.zone[var.default.domain_internal].id
}

resource "cloudflare_record" "router" {
  for_each = local.routers

  allow_overwrite = true
  name            = each.value.fqdn_external
  type            = length(regexall("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", each.value.network.public_address)) > 0 ? "A" : "CNAME"
  value           = each.value.network.public_address
  zone_id         = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_record" "server" {
  for_each = local.servers_merged_cloudflare

  allow_overwrite = true
  name            = each.value.fqdn_external
  type            = "CNAME"
  value           = each.value.network.public_address
  zone_id         = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_record" "vm_oci_ipv4" {
  for_each = local.vms_oci

  allow_overwrite = true
  name            = each.value.fqdn_external
  type            = "A"
  value           = data.oci_core_vnic.vm[each.key].public_ip_address
  zone_id         = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_record" "vm_oci_ipv6" {
  for_each = local.vms_oci

  allow_overwrite = true
  name            = each.value.fqdn_external
  type            = "AAAA"
  value           = data.oci_core_vnic.vm[each.key].ipv6addresses[0]
  zone_id         = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_record" "website" {
  for_each = local.websites

  allow_overwrite = true
  name            = each.value.name
  type            = length(regexall("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", each.value.value)) > 0 ? "A" : "CNAME"
  value           = each.value.value
  zone_id         = cloudflare_zone.zone[each.value.zone].id
}

resource "cloudflare_record" "wildcard" {
  for_each = local.cloudflare_records_merged

  allow_overwrite = true
  name            = "*.${each.value.name}"
  type            = "CNAME"
  value           = each.value.hostname
  zone_id         = each.value.zone_id
}

resource "cloudflare_tiered_cache" "zone" {
  for_each = local.zones

  cache_type = "off"
  zone_id    = cloudflare_zone.zone[each.key].id
}

resource "cloudflare_tunnel" "server" {
  for_each = local.servers_merged

  account_id = cloudflare_account.default.id
  name       = each.value.fqdn_external
  secret     = random_password.cloudflare_tunnel[each.key].result
}

resource "cloudflare_url_normalization_settings" "zone" {
  for_each = local.zones

  scope   = "incoming"
  type    = "cloudflare"
  zone_id = cloudflare_zone.zone[each.key].id
}

resource "cloudflare_zone" "zone" {
  for_each = local.zones

  account_id = cloudflare_account.default.id
  zone       = each.key
}

resource "cloudflare_zone_settings_override" "zone" {
  for_each = local.zones

  zone_id = cloudflare_zone.zone[each.key].id
}
