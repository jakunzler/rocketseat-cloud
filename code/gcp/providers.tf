terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.17.0"
    }
  }  
}

provider "google" {
  project = "spry-kingdom-457202-m4"
  region  = "us-central1"
}