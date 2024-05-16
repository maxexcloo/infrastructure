output "hosts" {
  value = local.merged_hosts
}

output "routers" {
  value = local.merged_routers
}

output "servers" {
  value = local.merged_servers
}

output "tags" {
  value = local.merged_tags
}

resource "local_file" "pyinfra_inventory" {
  filename = "../PyInfra/inventory.py"

  content = templatefile(
    "${path.module}/templates/pyinfra_inventory.tftpl",
    {
      hosts = local.merged_hosts
    }
  )
}

resource "local_file" "ssh_config" {
  filename = "${var.root.path}/.ssh/config"

  content = replace(
    templatefile(
      "${path.module}/templates/ssh_config.tftpl",
      {
        hosts = local.merged_hosts
      }
    ),
    "/[\n]{3,}/",
    "\n\n"
  )
}
