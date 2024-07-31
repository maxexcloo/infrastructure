output "b2_buckets" {
  sensitive = true
  value     = local.b2_buckets
}

output "cloudflare_api_tokens" {
  sensitive = true
  value     = local.cloudflare_api_tokens
}

output "cloudflare_tunnel_tokens" {
  sensitive = true
  value     = local.cloudflare_tunnel_tokens
}

output "database_passwords" {
  sensitive = true
  value     = local.database_passwords
}

output "resend_api_keys" {
  sensitive = true
  value     = local.resend_api_keys_merged
}

output "secret_hashes" {
  sensitive = true
  value     = local.secret_hashes
}

output "ssh_keys" {
  sensitive = true
  value     = local.ssh_keys
}

output "tailscale_tailnet_keys" {
  sensitive = true
  value     = local.tailscale_tailnet_keys_merged
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
        agent   = fileexists("/run/user/1000/ssh-agent.socket") ? "/run/user/1000/ssh-agent.socket" : "/Users/max.schaefer/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        devices = local.devices
        servers = local.servers_merged
      }
    ),
    "},\n]",
    "}\n]"
  )
}
