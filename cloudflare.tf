resource "cloudflare_account" "default" {
  name = var.terraform.cloudflare.email
}

resource "cloudflare_record" "dns" {
  for_each = local.dns

  name     = each.value.name == "@" ? each.value.zone : each.value.name
  priority = try(each.value.priority, null)
  type     = each.value.type
  value    = each.value.value
  zone_id  = cloudflare_zone.zone[each.value.zone].id
}

resource "cloudflare_record" "router" {
  for_each = local.routers

  name    = each.value.fqdn
  type    = length(regexall("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", each.value.network.public_address)) > 0 ? "A" : "CNAME"
  value   = each.value.network.public_address
  zone_id = cloudflare_zone.zone[var.default.domain].id
}

resource "cloudflare_record" "server" {
  for_each = local.servers_merged_cloudflare

  name    = each.value.fqdn
  type    = "CNAME"
  value   = each.value.network.public_address
  zone_id = cloudflare_zone.zone[var.default.domain].id
}

resource "cloudflare_record" "vm_oci_ipv4" {
  for_each = local.vms_oci

  name    = each.key
  type    = "A"
  value   = data.oci_core_vnic.vm[each.key].public_ip_address
  zone_id = cloudflare_zone.zone[var.default.domain].id
}

resource "cloudflare_record" "vm_oci_ipv6" {
  for_each = local.vms_oci

  name    = each.key
  type    = "AAAA"
  value   = data.oci_core_vnic.vm[each.key].ipv6addresses[0]
  zone_id = cloudflare_zone.zone[var.default.domain].id
}

resource "cloudflare_record" "website" {
  for_each = local.websites

  name    = each.value.name
  type    = length(regexall("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", each.value.value)) > 0 ? "A" : "CNAME"
  value   = each.value.value
  zone_id = cloudflare_zone.zone[each.value.zone].id
}

resource "cloudflare_record" "wildcard" {
  for_each = local.cloudflare_records_merged

  name    = "*.${each.value.name}"
  type    = "CNAME"
  value   = each.value.name
  zone_id = each.value.zone_id
}

resource "cloudflare_tunnel" "server" {
  for_each = local.servers_merged

  account_id = cloudflare_account.default.id
  name       = each.key
  secret     = random_password.cloudflare_tunnel[each.key].result
}

resource "cloudflare_zone" "zone" {
  for_each = local.zones

  account_id = cloudflare_account.default.id
  zone       = each.key
}
