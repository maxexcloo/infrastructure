data "github_user" "config" {
  username = ""
}

resource "github_repository_file" "server-debian" {
  for_each = {
    for i, server in var.servers : "${server.location}-${server.hostname}" => server
    if server.type == "debian"
  }

  file                = "debian/${each.key}"
  overwrite_on_create = true
  repository          = var.terraform.github.repository

  content = replace(
    templatefile(
      "${path.module}/templates/debian.tftpl",
      {
        root_domain = var.root.domain
        ssh_keys    = data.github_user.config.ssh_keys
        server      = each.value
      }
    ),
    "/[\n]+/",
    "\n"
  )
}
