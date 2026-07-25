terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# An alert policy with no notification channel raises incidents that nobody is
# told about, so the example creates one and attaches it.
#
# Note: for channel types whose configuration carries a secret (a Slack or
# PagerDuty webhook URL with an embedded token, for example) use the provider's
# `sensitive_labels` block rather than `labels` — values in `labels` are stored
# and displayed in plaintext.
resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Alerting email"
  type         = "email"

  labels = {
    email_address = var.notification_email
  }
}

module "monitoring" {
  source = "../.."

  project_id      = var.project_id
  display_name    = "High CPU utilization"
  threshold_value = 0.8
  duration        = "120s"

  notification_channels = [google_monitoring_notification_channel.email.id]
}

variable "project_id" {
  description = "Project ID to create the example alert policy in."
  type        = string
}

variable "region" {
  description = "Region for the google provider."
  type        = string
  default     = "us-central1"
}

variable "notification_email" {
  description = "Email address notified when the example alert policy fires."
  type        = string
}

output "alert_policy_name" {
  value = module.monitoring.name
}

output "notification_channel_id" {
  value = google_monitoring_notification_channel.email.id
}
