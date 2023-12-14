terraform {
  required_version = "~>1.3"

  backend "gcs" {
    bucket  = "9c40821c8622dce9-bucket"
    prefix  = "terraform/state"
  }
}