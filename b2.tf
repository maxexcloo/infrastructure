data "b2_account_info" "default" {}

resource "b2_application_key" "website" {
  for_each = {
    for k, website in local.websites : k => website
    if website.b2_bucket
  }

  bucket_id = b2_bucket.website[each.key].id
  key_name  = each.value.app_name

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

resource "b2_bucket" "website" {
  for_each = {
    for k, website in local.websites : k => website
    if website.b2_bucket
  }

  bucket_name = "${each.value.app_name}-${random_string.b2_bucket[each.key].result}"
  bucket_type = "allPrivate"
}
