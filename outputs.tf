output "b2" {
  sensitive = true
  value     = local.output_b2
}

output "cloudflare_tunnel_tokens" {
  sensitive = true
  value     = local.output_cloudflare_tunnel_tokens
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
  content  = templatefile("./templates/docker/caddy/docker-compose.yaml.tftpl", { cloudflare_api_token = cloudflare_api_token.caddy.value })
  filename = "./pyinfra/docker/caddy/docker-compose.yaml"
}

resource "local_file" "docker_portainer_agent" {
  content  = templatefile("./templates/docker/portainer/docker-compose.agent.yaml.tftpl", {})
  filename = "./pyinfra/docker/portainer/docker-compose.agent.yaml"
}

resource "local_file" "docker_portainer_service" {
  content  = templatefile("./templates/docker/portainer/docker-compose.service.yaml.tftpl", { default = var.default })
  filename = "./pyinfra/docker/portainer/docker-compose.service.yaml"
}

resource "local_file" "pyinfra_inventory" {
  filename = "./pyinfra/inventory.py"

  content = templatefile(
    "./templates/pyinfra/inventory.py.tftpl",
    {
      cloudflare_tunnel_tokens = local.output_cloudflare_tunnel_tokens
      onepassword_vault        = var.terraform.onepassword.vault
      servers                  = local.filtered_servers_all
      tailscale_tailnet_keys   = local.output_tailscale_tailnet_keys
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
        ssh_port                = server.network.ssh_port
        ssh_user                = server.user.username
        b2                      = local.output_b2[k]
        cloudflare_tunnel_token = local.output_cloudflare_tunnel_tokens[k]
        flags                   = server.flags
        fqdn_external           = server.fqdn_external
        fqdn_internal           = server.fqdn_internal
        host                    = server.host
        location                = server.location
        name                    = server.name
        parent_name             = server.parent_name
        parent_type             = server.parent_type
        resend_api_key          = local.output_resend_api_keys[k]
        secret_hash             = local.output_secret_hashes[k]
        tag                     = server.tag
        type                    = server.type
      }
    }
  })
}

resource "local_file" "ssh_config" {
  filename = "../../.ssh/config"

  content = templatefile(
    "./templates/ssh/config.tftpl",
    {
      devices = local.merged_devices
      servers = local.filtered_servers_all
    }
  )
}

resource "local_file" "vscode_sftp" {
  filename = "../../.vscode/sftp.json"

  content = replace(
    templatefile(
      "./templates/vscode/sftp.json.tftpl",
      {
        devices = local.merged_devices
        servers = local.filtered_servers_all
      }
    ),
    "},\n]",
    "}\n]"
  )
}
