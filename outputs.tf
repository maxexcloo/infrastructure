output "server" {
  value = local.servers_merged
}

output "ssh_keys" {
  value = local.ssh_keys
}

resource "local_file" "pyinfra_inventory" {
  file_permission = "0644"
  filename        = "../PyInfra/inventory.py"


  content = templatefile(
    "./templates/pyinfra_inventory.tftpl",
    {
      cloudflare_tunnels = cloudflare_tunnel.server
      onepassword_vault  = var.terraform.onepassword.vault
      servers            = local.servers_merged
      tailscale_keys     = tailscale_tailnet_key.server
    }
  )
}

resource "local_file" "ssh_config" {
  file_permission = "0644"
  filename        = "${var.default.home}/.ssh/config"

  content = templatefile(
    "./templates/ssh_config.tftpl",
    {
      devices = var.devices
      servers = local.servers_merged
    }
  )
}
