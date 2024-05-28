resource "b2_application_key" "server" {
  for_each = local.servers_merged

  bucket_id = b2_bucket.server[each.key].id
  key_name  = each.value.host

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
  for_each = local.servers_merged

  bucket_name = "${each.value.host}-${random_string.b2_bucket[each.key].result}"
  bucket_type = "allPrivate"
}
