terraform {
  backend "gcs" {
    bucket = "spokane-mountaineers-tfstate"
    prefix = "gcloud-billing"
  }
}
