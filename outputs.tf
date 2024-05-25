output "server" {
  value = local.servers_merged
}

output "tags" {
  value = local.tags
}

resource "local_file" "pyinfra_inventory" {
  file_permission = "0644"
  filename        = "../PyInfra/inventory.py"


  content = trim(
    templatefile(
      "./templates/pyinfra_inventory.tftpl",
      {
        servers           = local.servers_merged
        onepassword_vault = var.terraform.onepassword.vault
      }
    ),
    "\n"
  )
}

resource "local_file" "ssh_config" {
  file_permission = "0644"
  filename        = "${var.default.home}/.ssh/config"

  content = trim(
    templatefile(
      "./templates/ssh_config.tftpl",
      {
        devices = var.devices
        servers = local.servers_merged
      }
    ),
    "\n"
  )
}
