resource "restapi_object" "server_resend_api_key" {
  for_each = local.servers_merged

  data         = jsonencode({ name = each.key })
  id_attribute = "id"
  path         = "/api-keys"
  provider     = restapi.resend
  read_path    = "/api-keys"

  read_search = {
    query_string = ""
    results_key  = "data"
    search_key   = "name"
    search_value = each.key
  }
}

resource "restapi_object" "website_resend_api_key" {
  for_each = {
    for k, website in local.websites : k => website
    if website.enable_resend_api_key
  }

  data         = jsonencode({ name = each.value.app_name })
  id_attribute = "id"
  path         = "/api-keys"
  provider     = restapi.resend
  read_path    = "/api-keys"

  read_search = {
    query_string = ""
    results_key  = "data"
    search_key   = "name"
    search_value = each.value.app_name
  }
}
