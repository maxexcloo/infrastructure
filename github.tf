data "github_user" "default" {
  username = ""
}

resource "github_actions_variable" "portainer_portainer_url" {
  for_each = {
    for k, website in local.websites : k => website
    if website.app_type == "portainer"
  }

  repository    = each.value.name
  variable_name = "PORTAINER_URL"
  value         = each.value.url
}

resource "github_actions_secret" "portainer_stacks" {
  for_each = {
    for k, website in local.websites : k => website
    if website.app_type == "portainer"
  }

  plaintext_value = jsonencode(local.websites_merged_portainer)
  repository      = each.value.name
  secret_name     = "STACKS"
}

resource "github_repository_file" "gatus_config" {
  for_each = {
    for k, website in local.websites : k => website
    if website.app_type == "gatus"
  }

  file                = "${each.value.app_name}/config.yaml"
  overwrite_on_create = true
  repository          = "fly"

  content = templatefile(
    "./templates/gatus/config.yaml.tftpl",
    {
      default  = var.default
      servers  = local.servers_merged
      tags     = local.tags
      website  = each.value
      websites = local.websites
    }
  )
}
