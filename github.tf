data "github_user" "config" {
  username = ""
}

resource "github_repository_file" "virtual_machine-debian" {
  for_each = {
    for i, virtual_machine in var.virtual_machines : "${virtual_machine.location}-${virtual_machine.hostname}" => virtual_machine if virtual_machine.type == "coolify" || virtual_machine.type == "debian"
  }

  file                = "vm-debian/${each.key}"
  overwrite_on_create = true
  repository          = "public"

  content = replace(
    templatefile(
      "${path.module}/templates/debian.tftpl",
      {
        root_domain     = var.root_domain
        ssh_keys        = data.github_user.config.ssh_keys
        virtual_machine = each.value
      }
    ),
    "/[\n]+/",
    "\n"
  )
}
