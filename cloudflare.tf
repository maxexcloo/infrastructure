data "cloudflare_account_api_token_permission_groups_list" "default" {
  account_id = cloudflare_account.default.id
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "server" {
  for_each = cloudflare_zero_trust_tunnel_cloudflared.server

  account_id = cloudflare_account.default.id
  tunnel_id  = each.value.id
}

resource "cloudflare_account" "default" {
  name = var.terraform.cloudflare.email
  type = "standard"
}

resource "cloudflare_account_token" "server" {
  for_each = local.filtered_servers_all

  account_id = cloudflare_account.default.id
  name       = each.key

  policies = [
    {
      effect = "allow"
      permission_groups = [
        for permission_id in sort([
          one([
            for group in data.cloudflare_account_api_token_permission_groups_list.default.result : group.id if group.name == "DNS Write"
          ]),
          one([
            for group in data.cloudflare_account_api_token_permission_groups_list.default.result : group.id if group.name == "Zone Read"
          ])
        ]) : { id = permission_id }
      ]
      resources = {
        "com.cloudflare.api.account.zone.${cloudflare_zone.zone[var.default.domain_internal].id}" = "*"
      }
    }
  ]
}

resource "cloudflare_dns_record" "dns" {
  for_each = local.merged_dns

  content  = each.value.content
  name     = each.value.name == "@" ? each.value.zone : "${each.value.name}.${each.value.zone}"
  priority = each.value.priority
  ttl      = 1
  type     = each.value.type
  zone_id  = cloudflare_zone.zone[each.value.zone].id
}

resource "cloudflare_dns_record" "internal_ipv4" {
  for_each = local.filtered_tailscale_devices

  content = each.value.private_ipv4
  name    = each.value.fqdn_internal
  ttl     = 1
  type    = "A"
  zone_id = cloudflare_zone.zone[var.default.domain_internal].id
}

resource "cloudflare_dns_record" "internal_ipv6" {
  for_each = local.filtered_tailscale_devices

  content = each.value.private_ipv6
  name    = each.value.fqdn_internal
  ttl     = 1
  type    = "AAAA"
  zone_id = cloudflare_zone.zone[var.default.domain_internal].id
}

resource "cloudflare_dns_record" "noncloud" {
  for_each = {
    for k, server in local.filtered_servers_noncloud : k => server
    if length(server.networks) > 0
  }

  content = element(each.value.networks, 0).public_address
  name    = each.value.fqdn_external
  ttl     = 1
  type    = "CNAME"
  zone_id = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_dns_record" "router" {
  for_each = {
    for k, router in local.merged_routers : k => router
    if length(router.networks) > 0
  }

  content = element(each.value.networks, 0).public_address
  name    = each.value.fqdn_external
  ttl     = 1
  type    = "CNAME"
  zone_id = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_dns_record" "vm_ipv4" {
  for_each = {
    for k, vm in local.merged_vms : k => vm
    if length(vm.networks) > 0
  }

  content = element(each.value.networks, 0).public_ipv4
  name    = each.value.fqdn_external
  ttl     = 1
  type    = "A"
  zone_id = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_dns_record" "vm_ipv6" {
  for_each = {
    for k, vm in local.merged_vms : k => vm
    if length(vm.networks) > 0
  }

  content = element(each.value.networks, 0).public_ipv6
  name    = each.value.fqdn_external
  ttl     = 1
  type    = "AAAA"
  zone_id = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_dns_record" "vm_oci_ipv4" {
  for_each = data.oci_core_vnic.vm

  content = each.value.public_ip_address
  name    = local.merged_vms_oci[each.key].fqdn_external
  ttl     = 1
  type    = "A"
  zone_id = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_dns_record" "vm_oci_ipv6" {
  for_each = data.oci_core_vnic.vm

  content = element(data.oci_core_vnic.vm[each.key].ipv6addresses, 0)
  name    = local.merged_vms_oci[each.key].fqdn_external
  ttl     = 1
  type    = "AAAA"
  zone_id = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_dns_record" "wildcard" {
  for_each = local.filtered_cloudflare_dns_record_wildcard

  content = each.value.name
  name    = "*.${each.value.name}"
  ttl     = 1
  type    = "CNAME"
  zone_id = each.value.zone_id
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "server" {
  for_each = local.filtered_servers_all

  account_id = cloudflare_account.default.id
  config_src = "cloudflare"
  name       = each.key
}

resource "cloudflare_zone" "zone" {
  for_each = var.dns

  name = each.key

  account = {
    id = cloudflare_account.default.id
  }
}
