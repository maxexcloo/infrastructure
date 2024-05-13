resource "cloudflare_account" "root" {
  name = var.root_email
}

resource "cloudflare_record" "routers" {
  for_each = {
    for i, router in var.routers : "${router.location}.${var.root_domain}" => router
  }

  name    = each.value.location
  type    = try(each.value.ddns, false) == false ? "A" : "CNAME"
  value   = try(each.value.ddns, each.value.ip)
  zone_id = cloudflare_zone.root[var.root_domain].id
}

resource "cloudflare_record" "servers" {
  for_each = {
    for i, server in var.servers : "${server.hostname}.${server.location}.${var.root_domain}" => server
    if server.type != "oci"
  }

  name    = "${each.value.hostname}.${each.value.location}"
  type    = "CNAME"
  value   = try(each.value.ddns, cloudflare_record.routers["${each.value.location}.${var.root_domain}"].hostname)
  zone_id = cloudflare_zone.root[var.root_domain].id
}

resource "cloudflare_record" "servers_oci_ipv4" {
  for_each = data.oci_core_vnic.config

  name    = replace(each.key, ".${var.root_domain}", "")
  type    = "A"
  value   = each.value.public_ip_address
  zone_id = cloudflare_zone.root[var.root_domain].id
}

resource "cloudflare_record" "servers_oci_ipv6" {
  for_each = data.oci_core_vnic.config

  name    = replace(each.key, ".${var.root_domain}", "")
  type    = "AAAA"
  value   = each.value.ipv6addresses[0]
  zone_id = cloudflare_zone.root[var.root_domain].id
}

resource "cloudflare_record" "virtual_machines" {
  for_each = {
    for i, virtual_machine in var.virtual_machines : "${virtual_machine.hostname}.${virtual_machine.location}.${var.root_domain}" => virtual_machine
  }

  name    = "${each.value.hostname}.${each.value.location}"
  type    = "CNAME"
  value   = try(each.value.ddns, cloudflare_record.servers["${each.value.parent}.${each.value.location}.${var.root_domain}"].hostname)
  zone_id = cloudflare_zone.root[var.root_domain].id
}

resource "cloudflare_record" "websites" {
  for_each = merge([
    for zone, records in var.websites : {
      for i, record in records : "${record.name == "@" ? "" : "${record.name}."}${zone}-${lower(record.type)}-${i}" => merge(
        record,
        {
          zone = zone,
        }
      )
    }
  ]...)

  name     = each.value.name == "@" ? each.value.zone : each.value.name
  priority = try(each.value.priority, null)
  type     = each.value.type
  value    = each.value.value
  zone_id  = cloudflare_zone.root[each.value.zone].id
}

resource "cloudflare_record" "wildcard" {
  for_each = {
    for k, v in merge(
      cloudflare_record.routers,
      cloudflare_record.servers,
      cloudflare_record.servers_oci_ipv4,
      cloudflare_record.servers_oci_ipv6,
      cloudflare_record.virtual_machines,
      cloudflare_record.websites
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
