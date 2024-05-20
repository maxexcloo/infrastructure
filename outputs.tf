# output "servers" {
#   value = local.servers
# }

# output "tags" {
#   value = local.tags
# }

resource "local_file" "pyinfra_inventory" {
  filename = "../PyInfra/inventory.py"

  content = templatefile(
    "./templates/pyinfra_inventory.tftpl",
    {
      servers = local.servers
    }
  )
}

resource "local_file" "ssh_config" {
  filename = "${var.default.home}/.ssh/config"

  content = templatefile(
    "./templates/ssh_config.tftpl",
    {
      servers = local.servers
    }
  )
}
