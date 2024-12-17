output "b2" {
  sensitive = true
  value     = local.output_b2
}

output "cloudflare_tunnels" {
  sensitive = true
  value     = local.output_cloudflare_tunnels
}

output "init_commands" {
  sensitive = true
  value     = local.output_init_commands
}

output "user_data" {
  sensitive = true
  value     = local.output_user_data
}

output "resend_api_keys" {
  sensitive = true
  value     = local.output_resend_api_keys
}

output "secret_hashes" {
  sensitive = true
  value     = local.output_secret_hashes
}

output "ssh" {
  sensitive = true
  value     = local.output_ssh
}

output "tailscale_tailnet_keys" {
  sensitive = true
  value     = local.output_tailscale_tailnet_keys
}

resource "local_file" "services_infrastructure" {
  filename = "../Services/terraform.tfvars.json"

  content = jsonencode({
    default = var.default
    devices = var.devices
    tags    = local.merged_tags

    servers = {
      for k, server in local.output_servers_all : k => {
        b2                    = local.output_b2[k]
        cloudflare_tunnel     = try(local.output_cloudflare_tunnels[k], null)
        flags                 = server.flags
        fqdn_external         = server.fqdn_external
        fqdn_internal         = server.fqdn_internal
        location              = server.location
        parent_flags          = server.parent_flags
        parent_name           = server.parent_name
        resend_api_key        = local.output_resend_api_keys[k]
        secret_hash           = local.output_secret_hashes[k]
        tag                   = server.tag
        tailscale_tailnet_key = try(local.output_tailscale_tailnet_keys[k], null)
        title                 = server.title

        services = [
          for service in local.output_services_all[k] : merge(
            service,
            {
              widgets = jsondecode(templatestring(jsonencode(service.widgets), {
                default = var.default
                service = service

                server = merge(
                  server,
                  {
                    password = onepassword_item.server[k].password
                  }
                )
              }))
            }
          )
        ]
      }
    }
  })
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
