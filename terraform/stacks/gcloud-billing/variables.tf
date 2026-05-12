variable "billing_account_id" {
  description = "GCP billing account ID (format: XXXXXX-XXXXXX-XXXXXX). Found in Billing > Account Management in the GCP Console."
  type        = string
}

variable "project_id" {
  description = "GCP project ID used to create Cloud Monitoring notification channels."
  type        = string
}

variable "contact_emails" {
  description = "Email addresses to notify when a budget threshold is crossed."
  type        = list(string)
}

variable "monthly_ceiling_usd" {
  description = "Monthly spend ceiling in USD. Expected bill is $0 (free tier); this exists to catch surprise charges, not track a grant allocation."
  type        = number
  default     = 10
}
