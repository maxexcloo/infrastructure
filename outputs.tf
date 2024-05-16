# output "servers" {
#   value = local.merged_servers
# }

# output "tags" {
#   value = local.merged_tags
# }

resource "local_file" "pyinfra_inventory" {
  filename = "../PyInfra/inventory.py"

  content = templatefile(
    "${path.module}/templates/pyinfra_inventory.tftpl",
    {
      hosts = local.merged_servers
    }
  )
}

resource "local_file" "ssh_config" {
  filename = "${var.default.home}/.ssh/config"

  content = replace(
    templatefile(
      "${path.module}/templates/ssh_config.tftpl",
      {
        hosts = local.merged_servers
      }
    ),
    "/[\n]{3,}/",
    "\n\n"
  )
}
