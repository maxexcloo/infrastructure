data "ct_config" "server" {
  for_each = {
    for k, server in local.filtered_servers_all : k => server
    if server.config.enable_ignition
  }

  strict = true

  content = templatefile(
    "templates/ignition/content.bu",
    {
      cloudflare_api_token    = cloudflare_api_token.internal.value
      cloudflare_tunnel_token = try(local.output_cloudflare_tunnels[each.key].token, "")
      default                 = var.default
      k                       = each.key
      password_hash           = htpasswd_password.server[each.key].sha512
      server                  = each.value
      ssh_keys                = concat(data.github_user.default.ssh_keys, [local.output_ssh[each.key].public_key])
      tailscale_tailnet_key   = try(local.output_tailscale_tailnet_keys[each.key], "")
    }
  )
}
