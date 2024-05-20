resource "cloudflare_account" "default" {
  name = var.terraform.cloudflare.email
}

resource "cloudflare_record" "router" {
  for_each = {
    for k, v in local.merged_servers : k => v
    if v.tag == "router"
  }

  name    = each.value.location
  type    = length(regexall("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", each.value.network.public_address)) > 0 ? "A" : "CNAME"
  value   = each.value.network.public_address
  zone_id = cloudflare_zone.config[var.default.domain].id
}

resource "cloudflare_record" "server" {
  for_each = {
    for k, v in local.merged_servers : k => v
    if v.tag != "router" && v.parent_name != "oci"
  }

  name    = "${each.value.name}.${each.value.location}"
  type    = "CNAME"
  value   = try(each.value.network.public_address, cloudflare_record.router["${each.value.location}.${var.default.domain}"].name)
  zone_id = cloudflare_zone.config[var.default.domain].id
}

resource "cloudflare_record" "server_oci_ipv4" {
  for_each = {
    for k, v in local.merged_servers : k => v
    if v.parent_name == "oci"
  }

  name    = replace(each.key, ".${var.default.domain}", "")
  type    = "A"
  value   = data.oci_core_vnic.config[each.key].public_ip_address
  zone_id = cloudflare_zone.config[var.default.domain].id
}

resource "cloudflare_record" "server_oci_ipv6" {
  for_each = {
    for k, v in local.merged_servers : k => v
    if v.parent_name == "oci"
  }

  name    = replace(each.key, ".${var.default.domain}", "")
  type    = "AAAA"
  value   = data.oci_core_vnic.config[each.key].ipv6addresses[0]
  zone_id = cloudflare_zone.config[var.default.domain].id
}

resource "cloudflare_record" "website" {
  for_each = local.merged_websites

  name     = each.value.name == "@" ? each.value.zone : each.value.name
  priority = try(each.value.priority, null)
  type     = each.value.type
  value    = each.value.value
  zone_id  = cloudflare_zone.config[each.value.zone].id
}

resource "cloudflare_record" "wildcard" {
  for_each = {
    for k, v in merge(
      cloudflare_record.router,
      cloudflare_record.server,
      cloudflare_record.server_oci_ipv4,
      cloudflare_record.server_oci_ipv6,
      cloudflare_record.website
    ) : k => v
    if v.type == "A" || v.type == "AAAA" || v.type == "CNAME"
  }

  name    = "*.${each.value.name}"
  type    = "CNAME"
  value   = each.value.name
  zone_id = each.value.zone_id
}

resource "cloudflare_zone" "config" {
  for_each = var.websites

  account_id = cloudflare_account.default.id
  zone       = each.key
}
