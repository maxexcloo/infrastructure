output "b2" {
  sensitive = true
  value     = local.output_b2
}

output "cloud_config" {
  sensitive = true
  value     = local.output_cloud_config
}

output "cloudflare_tunnels" {
  sensitive = true
  value     = local.output_cloudflare_tunnels
}

output "init_commands" {
  sensitive = true
  value     = { for k, v in local.output_init_commands : k => join("\n", v) }
}

output "resend_api_keys" {
  sensitive = true
  value     = local.output_resend_api_keys
}

output "secret_hashes" {
  sensitive = true
  value     = local.output_secret_hashes
}

output "servers" {
  sensitive = true
  value = jsonencode({
    for k, server in local.filtered_servers_all : k => merge(
      server,
      {
        b2                    = local.output_b2[k]
        name                  = k
        password              = onepassword_item.server[k].password
        resend_api_key        = local.output_resend_api_keys[k]
        secret_hash           = local.output_secret_hashes[k]
        tailscale_tailnet_key = local.output_tailscale_tailnet_keys[k]
      }
    )
  })
}

output "tailscale_tailnet_keys" {
  sensitive = true
  value     = local.output_tailscale_tailnet_keys
}

resource "local_file" "ssh_config" {
  filename = "../../.ssh/config"

  content = templatefile(
    "templates/ssh/config",
    {
      devices = local.merged_devices
      servers = local.filtered_servers_all
    }
  )
}
