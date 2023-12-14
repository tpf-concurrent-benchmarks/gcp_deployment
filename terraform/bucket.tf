resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_kms_key_ring" "terraform_state" {
  name     = "${random_id.bucket_prefix.hex}-bucket"
  location = "us"
}

resource "google_kms_crypto_key" "terraform_state_bucket" {
  name            = "test-terraform-state-bucket"
  key_ring        = google_kms_key_ring.terraform_state.id
  rotation_period = "86400s"

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_storage_bucket" "default" {
  name          = "${random_id.bucket_prefix.hex}-bucket"
  force_destroy = false
  location      = "US"

  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
  encryption {
    default_kms_key_name = google_kms_crypto_key.terraform_state_bucket.id
  }
  depends_on = [
    google_project_iam_member.default
  ]
}

data "google_storage_bucket_object_content" "key_pem" {
  name   = "key.pem"
  bucket = google_storage_bucket.default.name
}

data "google_storage_bucket_object_content" "key_pub" {
  name   = "key.pub"
  bucket = google_storage_bucket.default.name
}