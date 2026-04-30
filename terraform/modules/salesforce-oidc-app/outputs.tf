output "client_id" {
  description = "Application (client) ID. Paste into Salesforce Auth Provider 'Consumer Key'."
  value       = azuread_application.this.client_id
}

output "client_secret" {
  description = "Client secret value. Paste into Salesforce Auth Provider 'Consumer Secret'. Sensitive."
  value       = azuread_application_password.this.value
  sensitive   = true
}

output "tenant_id" {
  description = "Directory (tenant) ID, for reference."
  value       = data.azuread_client_config.current.tenant_id
}

output "object_id" {
  description = "App Registration object ID. Useful when granting admin consent or scripting against the Graph API."
  value       = azuread_application.this.object_id
}
