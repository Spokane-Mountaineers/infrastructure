output "subscription_id" {
  description = "Azure subscription ID being monitored."
  value       = data.azurerm_subscription.current.subscription_id
}

output "canary_budget_id" {
  description = "Resource ID of the canary budget (fires at $1 actual spend)."
  value       = azurerm_consumption_budget_subscription.canary.id
}

output "grant_budget_id" {
  description = "Resource ID of the monthly grant budget."
  value       = azurerm_consumption_budget_subscription.grant.id
}
