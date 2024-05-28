resource "restapi_object" "server_resend_key" {
  for_each = local.servers_merged

  data         = jsonencode({ name = each.value.host })
  id_attribute = "id"
  path         = "/api-keys"
  provider     = restapi.resend
  read_path    = "/api-keys"

  read_search = {
    query_string = ""
    results_key  = "data"
    search_key   = "name"
    search_value = each.value.host
  }
}

resource "restapi_object" "website_resend_key" {
  for_each = {
    for k, website in local.websites : k => website
    if website.resend_key_name != ""
  }

  data         = jsonencode({ name = each.value.resend_key_name })
  id_attribute = "id"
  path         = "/api-keys"
  provider     = restapi.resend
  read_path    = "/api-keys"

  read_search = {
    query_string = ""
    results_key  = "data"
    search_key   = "name"
    search_value = each.value.resend_key_name
  }
}
