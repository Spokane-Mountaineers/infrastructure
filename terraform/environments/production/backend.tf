terraform {
  backend "gcs" {
    bucket = "spokane-mountaineers-tfstate"
    prefix = "sign-in-with-microsoft/production"
  }
}
