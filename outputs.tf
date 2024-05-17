# output "servers" {
#   value = local.merged_servers
# }

# output "tags" {
#   value = local.merged_tags
# }

resource "local_file" "pyinfra_inventory" {
  filename = "../PyInfra/inventory.py"

  content = templatefile(
    "./templates/pyinfra_inventory.py.tftpl",
    {
      hosts = local.merged_servers
    }
  )
}

resource "local_file" "ssh_config" {
  filename = "${var.default.home}/.ssh/config"

  content = templatefile(
    "./templates/ssh_config.tftpl",
    {
      hosts = local.merged_servers
    }
  )
}
