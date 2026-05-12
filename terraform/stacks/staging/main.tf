module "salesforce_microsoft_signin" {
  source = "../../modules/salesforce-oidc-app"

  display_name  = "Spokane Mountaineers Sign-in (Staging)"
  redirect_uris = [var.salesforce_callback_url]
  logo_image    = filebase64("../../../assets/logo.png")
}
