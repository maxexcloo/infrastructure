data "cloudflare_api_token_permission_groups" "default" {}

resource "cloudflare_account" "default" {
  name = var.terraform.cloudflare.email
}

resource "cloudflare_api_token" "internal" {
  name = "internal"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.default.zone["DNS Write"],
      data.cloudflare_api_token_permission_groups.default.zone["Zone Read"]
    ]
    resources = {
      "com.cloudflare.api.account.zone.${cloudflare_zone.zone[var.default.domain_internal].id}" = "*"
    }
  }
}

resource "cloudflare_record" "dns" {
  for_each = local.merged_dns

  allow_overwrite = true
  content         = each.value.content
  name            = each.value.name == "@" ? each.value.zone : each.value.name
  priority        = each.value.priority
  type            = each.value.type
  zone_id         = cloudflare_zone.zone[each.value.zone].id
}

resource "cloudflare_record" "internal_ipv4" {
  for_each = local.filtered_tailscale_devices

  allow_overwrite = true
  content         = each.value.private_ipv4
  name            = each.value.fqdn_internal
  type            = "A"
  zone_id         = cloudflare_zone.zone[var.default.domain_internal].id
}

resource "cloudflare_record" "internal_ipv6" {
  for_each = local.filtered_tailscale_devices

  allow_overwrite = true
  content         = each.value.private_ipv6
  name            = each.value.fqdn_internal
  type            = "AAAA"
  zone_id         = cloudflare_zone.zone[var.default.domain_internal].id
}

resource "cloudflare_record" "noncloud" {
  for_each = {
    for k, server in local.filtered_servers_noncloud : k => server
    if length(server.networks) > 0
  }

  allow_overwrite = true
  content         = element(each.value.networks, 0).public_address
  name            = each.value.fqdn_external
  type            = "CNAME"
  zone_id         = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_record" "router" {
  for_each = {
    for k, router in local.merged_routers : k => router
    if length(router.networks) > 0
  }

  allow_overwrite = true
  content         = element(each.value.networks, 0).public_address
  name            = each.value.fqdn_external
  type            = "CNAME"
  zone_id         = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_record" "vm_ipv4" {
  for_each = {
    for k, vm in local.merged_vms : k => vm
    if length(vm.networks) > 0
  }

  allow_overwrite = true
  content         = element(each.value.networks, 0).public_ipv4
  name            = each.value.fqdn_external
  type            = "A"
  zone_id         = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_record" "vm_ipv6" {
  for_each = {
    for k, vm in local.merged_vms : k => vm
    if length(vm.networks) > 0
  }

  allow_overwrite = true
  content         = element(each.value.networks, 0).public_ipv6
  name            = each.value.fqdn_external
  type            = "AAAA"
  zone_id         = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_record" "vm_oci_ipv4" {
  for_each = data.oci_core_vnic.vm

  allow_overwrite = true
  content         = each.value.public_ip_address
  name            = local.merged_vms_oci[each.key].fqdn_external
  type            = "A"
  zone_id         = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_record" "vm_oci_ipv6" {
  for_each = data.oci_core_vnic.vm

  allow_overwrite = true
  content         = element(data.oci_core_vnic.vm[each.key].ipv6addresses, 0)
  name            = local.merged_vms_oci[each.key].fqdn_external
  type            = "AAAA"
  zone_id         = cloudflare_zone.zone[var.default.domain_external].id
}

resource "cloudflare_record" "wildcard" {
  for_each = local.filtered_cloudflare_records_wildcard

  allow_overwrite = true
  content         = each.value.hostname
  name            = "*.${each.value.name}"
  type            = "CNAME"
  zone_id         = each.value.zone_id
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "server" {
  for_each = {
    for k, server in local.filtered_servers_all : k => server
    if contains(server.flags, "cloudflared")
  }

  account_id = cloudflare_account.default.id
  config_src = "cloudflare"
  name       = each.key
  secret     = random_password.cloudflare_tunnel[each.key].result
}

resource "cloudflare_zone" "zone" {
  for_each = var.dns

  account_id = cloudflare_account.default.id
  zone       = each.key
}
