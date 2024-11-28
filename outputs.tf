output "b2" {
  sensitive = true
  value     = local.output_b2
}

output "cloudflare_tunnels" {
  sensitive = true
  value     = local.output_cloudflare_tunnels
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

resource "local_file" "docker_caddy" {
  filename = "pyinfra/docker/caddy/docker-compose.yaml"

  content = templatefile(
    "templates/docker/caddy/docker-compose.yaml.tftpl",
    {
      cloudflare_api_token = cloudflare_api_token.caddy.value
      email                = var.default.email
    }
  )
}

resource "local_file" "docker_portainer_agent" {
  content  = templatefile("templates/docker/portainer/docker-compose.agent.yaml.tftpl", {})
  filename = "pyinfra/docker/portainer/docker-compose.agent.yaml"
}

resource "local_file" "docker_portainer_service" {
  content  = templatefile("templates/docker/portainer/docker-compose.service.yaml.tftpl", { default = var.default })
  filename = "pyinfra/docker/portainer/docker-compose.service.yaml"
}

resource "local_file" "pyinfra_inventory" {
  filename = "pyinfra/inventory.py"

  content = templatefile(
    "templates/pyinfra/inventory.py.tftpl",
    {
      servers = {
        for k, server in local.filtered_servers_all : k => merge(
          server,
          {
            cloudflare_tunnel_token = try(local.output_cloudflare_tunnels[k].token, "")
            password                = onepassword_item.server[k].password
          }
        )
      }
    }
  )
}

resource "local_file" "services_infrastructure" {
  filename = "../Services/terraform.tfvars.json"

  content = jsonencode({
    default = var.default
    devices = var.devices
    tags    = local.merged_tags_tailscale

    servers = {
      for k, server in local.filtered_servers_all : k => {
        b2                    = local.output_b2[k]
        cloudflare_tunnel     = try(local.output_cloudflare_tunnels[k], null)
        flags                 = server.flags
        fqdn_external         = server.fqdn_external
        fqdn_internal         = server.fqdn_internal
        location              = server.location
        networks              = server.networks
        parent_flags          = server.parent_flags
        parent_name           = server.parent_name
        resend_api_key        = local.output_resend_api_keys[k]
        secret_hash           = local.output_secret_hashes[k]
        tag                   = server.tag
        tailscale_tailnet_key = try(local.output_tailscale_tailnet_keys[k], null)
        title                 = server.title
        users                 = server.users

        services = [
          for service in local.filtered_servers_services[k] : merge(
            service,
            {
              widget = jsondecode(templatestring(jsonencode(service.widget), {
                default  = var.default
                password = onepassword_item.server[k].password
                server   = server
                url      = service.url
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
    "templates/ssh/config.tftpl",
    {
      devices = local.merged_devices
      servers = local.filtered_servers_all
    }
  )
}

resource "local_file" "vscode_sftp" {
  filename = "../.vscode/sftp.json"

  content = replace(
    templatefile(
      "templates/vscode/sftp.json.tftpl",
      {
        devices = local.merged_devices
        servers = local.filtered_servers_all
      }
    ),
    "},\n]",
    "}\n]"
  )
}
