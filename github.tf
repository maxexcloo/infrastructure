data "github_user" "default" {
  username = ""
}

resource "github_actions_secret" "portainer_cloudflare_api_tokens" {
  for_each = {
    for k, website in local.websites : k => website
    if website.app_type == "portainer"
  }

  plaintext_value = jsonencode(local.cloudflare_api_tokens)
  repository      = each.value.name
  secret_name     = "CLOUDFLARE_API_TOKENS"
}

resource "github_actions_secret" "portainer_database_passwords" {
  for_each = {
    for k, website in local.websites : k => website
    if website.app_type == "portainer"
  }

  plaintext_value = jsonencode(local.database_passwords)
  repository      = each.value.name
  secret_name     = "DATABASE_PASSWORDS"
}

resource "github_actions_secret" "portainer_resend_api_keys" {
  for_each = {
    for k, website in local.websites : k => website
    if website.app_type == "portainer"
  }

  plaintext_value = jsonencode(local.resend_api_keys_merged)
  repository      = each.value.name
  secret_name     = "RESEND_API_KEYS"
}

resource "github_actions_secret" "portainer_secret_hashes" {
  for_each = {
    for k, website in local.websites : k => website
    if website.app_type == "portainer"
  }

  plaintext_value = jsonencode(local.secret_hashes)
  repository      = each.value.name
  secret_name     = "SECRET_HASHES"
}

resource "github_actions_secret" "portainer_websites" {
  for_each = {
    for k, website in local.websites : k => website
    if website.app_type == "portainer"
  }

  plaintext_value = jsonencode(local.websites)
  repository      = each.value.name
  secret_name     = "WEBSITES"
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

resource "github_actions_variable" "portainer_servers" {
  for_each = {
    for k, website in local.websites : k => website
    if website.app_type == "portainer"
  }

  repository    = each.value.name
  variable_name = "SERVERS"
  value         = jsonencode(local.servers_merged)
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
