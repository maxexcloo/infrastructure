output "b2_buckets" {
  value = local.b2_buckets
}

output "cloudflare_api_tokens" {
  value = local.cloudflare_api_tokens
}

output "cloudflare_tunnel_tokens" {
  value = local.cloudflare_tunnel_tokens
}

output "resend_api_keys" {
  value = local.resend_api_keys_merged
}

output "ssh_keys" {
  value = local.ssh_keys
}

output "tailscale_tailnet_keys" {
  value = local.tailscale_tailnet_keys_merged
}

resource "local_file" "pyinfra_inventory" {
  file_permission = "0644"
  filename        = "../PyInfra/inventory.py"

  content = templatefile(
    "./templates/pyinfra/inventory.py.tftpl",
    {
      cloudflare_tunnel_tokens = local.cloudflare_tunnel_tokens
      onepassword_vault        = var.terraform.onepassword.vault
      servers                  = local.servers_merged
      tailscale_tailnet_keys   = local.tailscale_tailnet_keys_merged
    }
  )
}

resource "local_file" "ssh_config" {
  file_permission = "0644"
  filename        = "${var.default.home}/.ssh/config"

  content = templatefile(
    "./templates/ssh/config.tftpl",
    {
      devices = local.devices
      servers = local.servers_merged
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
        devices = local.devices
        servers = local.servers_merged
      }
    ),
    "},\n]",
    "}\n]"
  )
}
