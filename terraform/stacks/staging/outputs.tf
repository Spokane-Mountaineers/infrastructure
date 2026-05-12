output "client_id" {
  description = "Application (client) ID. Paste into Salesforce Auth Provider 'Consumer Key' on the staging org."
  value       = module.salesforce_microsoft_signin.client_id
}

output "client_secret" {
  description = "Client secret value. Paste into Salesforce Auth Provider 'Consumer Secret' on the staging org. Sensitive."
  value       = module.salesforce_microsoft_signin.client_secret
  sensitive   = true
}

output "tenant_id" {
  description = "Directory (tenant) ID, for reference."
  value       = module.salesforce_microsoft_signin.tenant_id
}
