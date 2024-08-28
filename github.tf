data "github_user" "default" {
  username = ""
}

resource "github_actions_secret" "portainer_secrets" {
  for_each = {
    for k, website in local.merged_websites : k => website
    if website.app_type == "portainer"
  }

  plaintext_value = jsonencode(var.portainer_secrets)
  repository      = each.value.name
  secret_name     = "SECRETS"
}

resource "github_actions_secret" "portainer_servers" {
  for_each = {
    for k, website in local.merged_websites : k => website
    if website.app_type == "portainer"
  }

  plaintext_value = jsonencode(local.filtered_servers_portainer)
  repository      = each.value.name
  secret_name     = "SERVERS"
}

resource "github_actions_secret" "portainer_websites" {
  for_each = {
    for k, website in local.merged_websites : k => website
    if website.app_type == "portainer"
  }

  plaintext_value = jsonencode(local.filtered_websites_portainer)
  repository      = each.value.name
  secret_name     = "WEBSITES"
}

resource "github_actions_variable" "portainer_defaults" {
  for_each = {
    for k, website in local.merged_websites : k => website
    if website.app_type == "portainer"
  }

  repository    = each.value.name
  value         = jsonencode(local.filtered_defaults_portainer)
  variable_name = "DEFAULTS"
}

resource "github_actions_variable" "portainer_portainer_url" {
  for_each = {
    for k, website in local.merged_websites : k => website
    if website.app_type == "portainer"
  }

  repository    = each.value.name
  variable_name = "PORTAINER_URL"
  value         = each.value.url
}

resource "github_repository_file" "gatus_config" {
  for_each = {
    for k, website in local.merged_websites : k => website
    if website.app_type == "gatus"
  }

  file                = "${each.value.app_name}/config.yaml"
  overwrite_on_create = true
  repository          = "fly"

  content = templatefile(
    "./templates/gatus/config.yaml.tftpl",
    {
      default  = var.default
      servers  = local.filtered_servers_all
      tags     = local.merged_tags
      website  = each.value
      websites = local.merged_websites
    }
  )
}
