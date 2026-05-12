variable "salesforce_callback_url" {
  description = "Salesforce-generated callback URL for the Microsoft Auth Provider in the production org. Use a placeholder for the first apply, then update once Salesforce has saved the Auth Provider."
  type        = string
}
