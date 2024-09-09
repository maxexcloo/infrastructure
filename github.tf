data "github_user" "default" {
  username = ""
}

resource "github_repository_file" "services_fly_gatus_infrastructure" {
  file                = "fly/excloo-uptime/config/infrastructure.yaml"
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

resource "github_repository_file" "services_servers" {
  content             = jsonencode({ servers = local.output_servers })
  file                = "servers.auto.tfvars.json"
  overwrite_on_create = true
  repository          = "Services"
}
