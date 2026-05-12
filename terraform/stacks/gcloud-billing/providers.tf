provider "google" {
  # Authenticates via Application Default Credentials established by
  # `gcloud auth application-default login`. See docs/bootstrap.md.
  project = var.project_id

  # billingbudgets.googleapis.com requires a quota project when using ADC.
  billing_project       = var.project_id
  user_project_override = true
}
