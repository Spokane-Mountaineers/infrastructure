terraform {
  backend "gcs" {
    bucket = "spokane-mountaineers-tfstate"
    prefix = "azure-billing"
  }
}
