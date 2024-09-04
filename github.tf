data "github_user" "default" {
  username = ""
}

resource "github_repository_file" "gatus_config" {
  file                = "fly/gatus/config.infrastructure.yaml"
  overwrite_on_create = true
  repository          = "Services"

  content = templatefile(
    "./templates/gatus/config.infrastructure.yaml.tftpl",
    {
      servers = local.filtered_servers_all
      tags    = local.merged_tags
    }
  )
}
