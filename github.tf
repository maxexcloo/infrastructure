data "github_user" "default" {
  username = var.terraform.github.username
}

resource "github_repository_file" "services_config_gatus_infrastructure" {
  file                = "config/fly-gatus/infrastructure.yaml"
  overwrite_on_create = true
  repository          = "Services"

  content = templatefile(
    "./templates/gatus/infrastructure.yaml.tftpl",
    {
      servers = local.filtered_servers_all
      tags    = local.merged_tags_tailscale
    }
  )
}
