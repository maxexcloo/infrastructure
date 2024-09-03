data "b2_account_info" "default" {}

resource "b2_application_key" "server" {
  for_each = local.filtered_servers_all

  bucket_id = b2_bucket.server[each.key].id
  key_name  = each.key

  capabilities = [
    "deleteFiles",
    "listBuckets",
    "listFiles",
    "readBucketEncryption",
    "readBucketNotifications",
    "readBucketReplications",
    "readBuckets",
    "readFiles",
    "shareFiles",
    "writeBucketEncryption",
    "writeBucketNotifications",
    "writeBucketReplications",
    "writeFiles"
  ]
}

resource "b2_bucket" "server" {
  for_each = local.filtered_servers_all

  bucket_name = "${each.key}-${random_password.b2_bucket_server[each.key].result}"
  bucket_type = "allPrivate"
}
