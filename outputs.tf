output "b2_buckets" {
  sensitive = true
  value     = local.output_b2_buckets
}

output "cloudflare_tunnel_tokens" {
  sensitive = true
  value     = local.output_cloudflare_tunnel_tokens
}

output "resend_api_keys" {
  sensitive = true
  value     = local.output_resend_api_keys
}

output "ssh_keys" {
  sensitive = true
  value     = local.output_ssh_keys
}

output "tailscale_tailnet_keys" {
  sensitive = true
  value     = local.output_tailscale_tailnet_keys
}

resource "local_file" "pyinfra_inventory" {
  file_permission = "0644"
  filename        = "./pyinfra/inventory.enc.py"

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

resource "local_file" "ssh_config" {
  file_permission = "0644"
  filename        = "${var.default.home}/.ssh/config"

  content = templatefile(
    "./templates/ssh/config.tftpl",
    {
      devices = local.merged_devices
      servers = local.filtered_servers_all
    }
  )
}

resource "local_file" "vscode_sftp" {
  file_permission = "0644"
  filename        = "${var.default.home}/.vscode/sftp.json"

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
