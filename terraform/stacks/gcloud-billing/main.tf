# gcloud uses the Service Usage API (always pre-enabled) rather than CRM,
# so this breaks the bootstrap cycle without any manual step.
resource "terraform_data" "bootstrap_cloudresourcemanager" {
  triggers_replace = var.project_id

  provisioner "local-exec" {
    command = "gcloud services enable cloudresourcemanager.googleapis.com --project=${var.project_id}"
  }
}

resource "google_project_service" "cloudresourcemanager" {
  project    = var.project_id
  service    = "cloudresourcemanager.googleapis.com"
  depends_on = [terraform_data.bootstrap_cloudresourcemanager]

  disable_on_destroy = false
}

resource "google_project_service" "billingbudgets" {
  project    = var.project_id
  service    = "billingbudgets.googleapis.com"
  depends_on = [google_project_service.cloudresourcemanager]

  disable_on_destroy = false
}

resource "time_sleep" "billingbudgets_propagation" {
  depends_on      = [google_project_service.billingbudgets]
  create_duration = "60s"
}

resource "google_monitoring_notification_channel" "email" {
  for_each = toset(var.contact_emails)

  display_name = "Budget Alert — ${each.value}"
  type         = "email"

  labels = {
    email_address = each.value
  }
}

locals {
  channel_ids = [for ch in google_monitoring_notification_channel.email : ch.id]
}

# Fires at $1 of actual spend — effectively "anything was billed."
# Expected monthly bill is $0; any charge here is unexpected.
resource "google_billing_budget" "canary" {
  depends_on      = [time_sleep.billingbudgets_propagation]
  billing_account = var.billing_account_id
  display_name    = "Canary — Any Billing Activity"

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "1"
    }
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = local.channel_ids
    disable_default_iam_recipients   = true
  }
}

# Two-stage ceiling: halfway and full. Not a grant — just a ceiling to
# catch runaway charges before they compound.
resource "google_billing_budget" "ceiling" {
  depends_on      = [time_sleep.billingbudgets_propagation]
  billing_account = var.billing_account_id
  display_name    = "Monthly Spend Ceiling"

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.monthly_ceiling_usd)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = local.channel_ids
    disable_default_iam_recipients   = true
  }
}
