resource "cloudflare_account" "root" {
  name = var.terraform.cloudflare.email
}

resource "cloudflare_record" "oci_ipv4" {
  for_each = data.oci_core_vnic.config

  name    = replace(each.key, ".${var.root.domain}", "")
  type    = "A"
  value   = each.value.public_ip_address
  zone_id = cloudflare_zone.root[var.root.domain].id
}

resource "cloudflare_record" "oci_ipv6" {
  for_each = data.oci_core_vnic.config

  name    = replace(each.key, ".${var.root.domain}", "")
  type    = "AAAA"
  value   = each.value.ipv6addresses[0]
  zone_id = cloudflare_zone.root[var.root.domain].id
}

resource "cloudflare_record" "router" {
  for_each = local.merged_routers

  name    = each.value.location
  type    = length(regexall("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", each.value.network.public_address)) > 0 ? "A" : "CNAME"
  value   = each.value.network.public_address
  zone_id = cloudflare_zone.root[var.root.domain].id
}

resource "cloudflare_record" "server" {
  for_each = local.merged_servers

  name    = "${each.value.hostname}.${each.value.location}"
  type    = "CNAME"
  value   = try(each.value.network.public_address, cloudflare_record.router["${each.value.location}.${var.root.domain}"].hostname)
  zone_id = cloudflare_zone.root[var.root.domain].id
}

resource "cloudflare_record" "website" {
  for_each = local.merged_websites

  name     = each.value.name == "@" ? each.value.zone : each.value.name
  priority = try(each.value.priority, null)
  type     = each.value.type
  value    = each.value.value
  zone_id  = cloudflare_zone.root[each.value.zone].id
}

resource "cloudflare_record" "wildcard" {
  for_each = {
    for k, v in merge(
      cloudflare_record.oci_ipv4,
      cloudflare_record.oci_ipv6,
      cloudflare_record.router,
      cloudflare_record.server,
      cloudflare_record.website
    ) : k => v
    if v.type == "A" || v.type == "AAAA" || v.type == "CNAME"
  }

  name    = "*.${each.value.name}"
  type    = "CNAME"
  value   = each.value.hostname
  zone_id = each.value.zone_id
}

resource "cloudflare_zone" "root" {
  for_each = var.websites

  account_id = cloudflare_account.root.id
  zone       = each.key
}
