data "b2_account_info" "default" {}

resource "b2_application_key" "server" {
  for_each = b2_bucket.server

  bucket_id    = each.value.id
  capabilities = ["all"]
  key_name     = each.key
}

resource "b2_bucket" "server" {
  for_each = local.filtered_servers.all

  bucket_name = "${each.key}-${random_password.b2[each.key].result}"
  bucket_type = "allPrivate"
}
