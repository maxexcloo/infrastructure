data "b2_account_info" "default" {}

resource "b2_application_key" "server" {
  for_each = b2_bucket.server

  bucket_id = each.value.id
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

  bucket_name = "${each.key}-${random_password.b2[each.key].result}"
  bucket_type = "allPrivate"
}
