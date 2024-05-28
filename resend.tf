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
