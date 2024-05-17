data "github_user" "config" {
  username = ""
}

resource "github_repository_file" "server-debian" {
  for_each = {
    for k, v in local.merged_servers : k => v
    if v.type == "debian"
  }

  file                = "debian/${each.key}"
  overwrite_on_create = true
  repository          = var.terraform.github.repository

  content = templatefile(
    "./templates/debian_preseed.tftpl",
    {
      default = var.default
      server  = each.value
    }
  )
}
