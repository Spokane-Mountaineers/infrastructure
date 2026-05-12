variable "contact_emails" {
  description = "Email addresses to notify when a budget threshold is crossed."
  type        = list(string)
}

variable "monthly_budget_usd" {
  description = "Monthly Azure grant budget in USD. Defaults to the monthly slice of the $2,000 annual nonprofit grant."
  type        = number
  default     = 166.67
}
