data "github_user" "default" {
  username = var.terraform.github.username
}

resource "github_repository_file" "services_config_gatus_infrastructure" {
  file                = "config/fly-excloo-uptime/infrastructure.yaml"
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

resource "github_repository_file" "services_config_homepage_docker" {
  file                = "config/docker-home/docker.yaml"
  overwrite_on_create = true
  repository          = "Services"

  content = templatefile(
    "./templates/homepage/docker.yaml.tftpl",
    {
      servers = local.filtered_servers_all
      tags    = local.merged_tags_tailscale
    }
  )
}

resource "github_repository_file" "services_config_homepage_widgets" {
  file                = "config/docker-home/widgets.yaml"
  overwrite_on_create = true
  repository          = "Services"

  content = templatefile(
    "./templates/homepage/widgets.yaml.tftpl",
    {
      servers = local.filtered_servers_all
      tags    = local.merged_tags_tailscale
    }
  )
}
