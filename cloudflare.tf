resource "cloudflare_account" "default" {
  name = var.default.email
}

resource "cloudflare_record" "dns" {
  for_each = local.merged_dns

  allow_overwrite = true
  content         = each.value.content
  name            = each.value.name == "@" ? each.value.zone : each.value.name
  priority        = try(each.value.priority, null)
  type            = each.value.type
  zone_id         = cloudflare_zone.zone[each.value.zone].id
}

resource "cloudflare_record" "router" {
  for_each = local.merged_routers

  allow_overwrite = true
  content         = each.value.network.public_address
  name            = each.value.fqdn_external
  type            = length(regexall("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", each.value.network.public_address)) > 0 ? "A" : "CNAME"
  zone_id         = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_record" "server" {
  for_each = local.filtered_servers_noncloud

  allow_overwrite = true
  content         = each.value.network.public_address
  name            = each.value.fqdn_external
  type            = "CNAME"
  zone_id         = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_record" "tailscale" {
  for_each = local.filtered_servers_all

  allow_overwrite = true
  content         = "${each.key}.ts.${var.default.domain_internal}"
  name            = each.value.fqdn_internal
  type            = "CNAME"
  zone_id         = cloudflare_zone.zone[var.default.domain_internal].id
}

resource "cloudflare_record" "vm_oci_ipv4" {
  for_each = local.merged_vms_oci

  allow_overwrite = true
  content         = data.oci_core_vnic.vm[each.key].public_ip_address
  name            = each.value.fqdn_external
  type            = "A"
  zone_id         = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_record" "vm_oci_ipv6" {
  for_each = local.merged_vms_oci

  allow_overwrite = true
  content         = data.oci_core_vnic.vm[each.key].ipv6addresses[0]
  name            = each.value.fqdn_external
  type            = "AAAA"
  zone_id         = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_record" "wildcard" {
  for_each = local.filtered_cloudflare_records

  allow_overwrite = true
  content         = each.value.hostname
  name            = "*.${each.value.name}"
  type            = "CNAME"
  zone_id         = each.value.zone_id
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "server" {
  for_each = local.filtered_servers_all

  account_id = cloudflare_account.default.id
  name       = each.value.fqdn_external
  secret     = random_password.cloudflare_tunnel[each.key].result
}

resource "cloudflare_zone" "zone" {
  for_each = var.dns

  account_id = cloudflare_account.default.id
  zone       = each.key
}
