data "azuread_client_config" "current" {}

resource "azuread_application" "this" {
  display_name = var.display_name

  # AzureADandPersonalMicrosoftAccount corresponds to the /common authority,
  # which lets any work, school, or personal Microsoft account complete sign-in.
  sign_in_audience = "AzureADandPersonalMicrosoftAccount"

  api {
    requested_access_token_version = 2
  }

  web {
    redirect_uris = var.redirect_uris

    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = false
    }
  }

  # Microsoft Graph delegated permissions: openid, profile, email, User.Read.
  # Resource app ID 00000003-0000-0000-c000-000000000000 = Microsoft Graph.
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      id   = "37f7f235-527c-4136-accd-4a02d197296e" # openid
      type = "Scope"
    }

    resource_access {
      id   = "14dad69e-099b-42c9-810b-d002981feec1" # profile
      type = "Scope"
    }

    resource_access {
      id   = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0" # email
      type = "Scope"
    }

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }

  # Surface the email claim in tokens so Salesforce's userinfo lookup gets it
  # for accounts whose email is present but not the primary identifier.
  optional_claims {
    id_token {
      name = "email"
    }

    access_token {
      name = "email"
    }
  }
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
}

resource "time_rotating" "client_secret" {
  rotation_days = var.client_secret_rotation_days
}

resource "azuread_application_password" "this" {
  application_id = azuread_application.this.id
  display_name   = "Salesforce OIDC client secret"
  end_date       = time_rotating.client_secret.rotation_rfc3339
}
