output "key_pem" {
  value = data.google_storage_bucket_object_content.key_pem.content
  sensitive = true
}

output "key_pub" {
  value = data.google_storage_bucket_object_content.key_pub.content
  sensitive = true
}