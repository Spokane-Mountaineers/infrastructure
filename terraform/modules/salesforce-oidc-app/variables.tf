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

variable "logo_image" {
  description = "Base64-encoded logo image (png, gif, or jpeg) for the App Registration. Once set, can only be changed by replacing with another image."
  type        = string
  default     = null
}

variable "client_secret_rotation_days" {
  description = "How often the client secret rotates. On each apply after this period elapses, the secret is replaced automatically."
  type        = number
  default     = 365
}
