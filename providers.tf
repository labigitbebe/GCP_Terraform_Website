terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.0.0"
    }
  }
}

provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  credentials = file(var.gcp_svc_key)
}