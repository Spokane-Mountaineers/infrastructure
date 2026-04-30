variable "display_name" {
  description = "Display name for the App Registration as it appears in the Microsoft Entra admin center."
  type        = string
}

variable "redirect_uris" {
  description = "Salesforce callback URL(s) for this App Registration. Salesforce surfaces the value once the Auth Provider is saved (e.g. https://<my-domain>.my.site.com/services/authcallback/Microsoft)."
  type        = list(string)

  validation {
    condition     = length(var.redirect_uris) > 0
    error_message = "At least one redirect URI is required."
  }
}

variable "client_secret_lifetime_hours" {
  description = "Validity window for the client secret. Defaults to one year; rotate before expiry by tainting azuread_application_password.this."
  type        = number
  default     = 8760
}
