data "b2_account_info" "default" {}

resource "b2_application_key" "server" {
  for_each = local.servers_merged

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

resource "b2_application_key" "website" {
  for_each = {
    for k, website in local.websites : k => website
    if website.enable_b2_bucket
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

resource "b2_bucket" "server" {
  for_each = local.servers_merged

  bucket_name = "${each.key}-${random_password.b2_bucket_server[each.key].result}"
  bucket_type = "allPrivate"
}

resource "b2_bucket" "website" {
  for_each = {
    for k, website in local.websites : k => website
    if website.enable_b2_bucket
  }

  bucket_name = "${each.value.app_name}-${random_password.b2_bucket_website[each.key].result}"
  bucket_type = "allPrivate"
}
