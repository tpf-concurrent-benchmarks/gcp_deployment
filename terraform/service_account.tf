resource "google_service_account" "default" {
  account_id   = "terraform-sa"
  display_name = "Terraform Service Account"
  project = var.project_id
}