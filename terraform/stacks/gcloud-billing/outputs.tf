output "canary_budget_id" {
  description = "Resource name of the canary budget (fires at $1 actual spend)."
  value       = google_billing_budget.canary.id
}

output "ceiling_budget_id" {
  description = "Resource name of the monthly ceiling budget."
  value       = google_billing_budget.ceiling.id
}

output "notification_channel_ids" {
  description = "Cloud Monitoring notification channel IDs created for each contact email."
  value       = { for email, ch in google_monitoring_notification_channel.email : email => ch.id }
}
