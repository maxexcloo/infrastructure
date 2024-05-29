output "b2_buckets" {
  value = local.b2_buckets
}

output "cloudflare_tunnels" {
  value = local.cloudflare_tunnels
}

output "resend_keys" {
  value = local.resend_keys_merged
}

output "servers" {
  value = local.servers_merged
}

output "ssh_keys" {
  value = local.ssh_keys
}

output "tailscale_keys" {
  value = local.tailscale_keys_merged
}

resource "local_file" "gatus_config" {
  for_each = {
    for k, website in local.websites : k => website
    if website.type == "gatus"
  }

  file_permission = "0644"
  filename        = "../Fly/${each.value.fly_app_name}/config.yaml"


  content = templatefile(
    "./templates/gatus/config.yaml.tftpl",
    {
      default  = var.default
      servers  = local.servers_merged
      tags     = local.tags
      website  = each.value
      websites = local.websites
    }
  )
}

resource "local_file" "pyinfra_inventory" {
  file_permission = "0644"
  filename        = "../PyInfra/inventory.py"


  content = templatefile(
    "./templates/pyinfra/inventory.py.tftpl",
    {
      cloudflare_tunnels = local.cloudflare_tunnels
      onepassword_vault  = var.terraform.onepassword.vault
      servers            = local.servers_merged
      tailscale_keys     = tailscale_tailnet_key.docker
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
