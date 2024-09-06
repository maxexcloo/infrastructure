resource "ssh_resource" "router" {
  for_each = {
    for k, router in local.merged_routers : k => router
    if data.external.connectivity_check_servers[k].result.reachable == "true"
  }

  agent = true
  host  = each.key
  port  = each.value.network.ssh_port
  user  = each.value.user.username

  commands = [
    "touch /etc/haproxy.infrastructure.cfg /etc/haproxy.services.cfg",
    "cat /etc/haproxy.infrastructure.cfg /etc/haproxy.services.cfg > /etc/haproxy.cfg",
    "/etc/init.d/dropbear restart",
    "/etc/init.d/haproxy restart"
  ]

  file {
    content     = "${join("\n", concat(data.github_user.default.ssh_keys, [local.output_ssh[each.key].public_key]))}\n"
    destination = "/etc/dropbear/authorized_keys"
  }

  file {
    destination = "/etc/haproxy.infrastructure.cfg"

    content = templatefile(
      "./templates/openwrt/haproxy.infrastructure.cfg.tftpl",
      {
        servers = {
          for k, v in local.filtered_servers_noncloud : k => v
          if k != each.key && v.location == each.value.location && v.network.private_address != ""
        }
      }
    )
  }
}

resource "ssh_resource" "server_docker" {
  for_each = {
    for k, server in local.filtered_servers_docker : k => server
    if data.external.connectivity_check_servers[k].result.reachable == "true"
  }

  agent = true
  host  = each.value.host
  port  = each.value.network.ssh_port
  user  = each.value.user.username

  pre_commands = [
    "mkdir -p ~/.env"
  ]

  file {
    destination = "~/.env/_server.env"

    content = <<-EOT
      SERVER_B2_BUCKET_APPLICATION_KEY="${local.output_b2[each.key].application_key}"
      SERVER_B2_BUCKET_APPLICATION_SECRET="${local.output_b2[each.key].application_secret}"
      SERVER_B2_BUCKET_BUCKET_NAME="${local.output_b2[each.key].bucket_name}"
      SERVER_B2_BUCKET_ENDPOINT="${local.output_b2[each.key].endpoint}"
      SERVER_CLOUDFLARE_TUNNEL_TOKEN="${local.output_cloudflare[each.key].tunnel_token}"
      SERVER_DOMAIN_DUCKDNS="${var.default.domain_duckdns}"
      SERVER_DOMAIN_EXTERNAL="${var.default.domain_external}"
      SERVER_DOMAIN_INTERNAL="${var.default.domain_internal}"
      SERVER_DOMAIN_ROOT="${var.default.domain_root}"
      SERVER_DUCKDNS_TOKEN="${var.default.duckdns_token}"
      SERVER_EMAIL="${var.default.email}"
      SERVER_FQDN_EXTERNAL="${each.value.fqdn_external}"
      SERVER_FQDN_INTERNAL="${each.value.fqdn_internal}"
      SERVER_HOST="${each.value.host}"
      SERVER_RESEND_API_KEY="${local.output_resend[each.key].api_key}"
      SERVER_SECRET_HASH="${local.output_secret_hashes[each.key].secret_hash}"
      SERVER_TAILSCALE_TAILNET_KEY="${local.output_tailscale[each.key].tailnet_key}"
      SERVER_TIMEZONE="${var.default.email}"
    EOT
  }
}
