resource "restapi_object" "resend_api_key_server" {
  for_each = local.filtered_servers.all

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
