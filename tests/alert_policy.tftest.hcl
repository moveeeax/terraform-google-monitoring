# Runs with a mocked provider: no credentials, no network, no API calls.
# `mock_provider` requires Terraform >= 1.7 / OpenTofu >= 1.7 to *run* the
# tests. The module itself still only requires >= 1.5, so consumers are
# unaffected — do not bump versions.tf for this file.
mock_provider "google" {}

variables {
  project_id            = "example-project"
  display_name          = "High CPU utilization"
  notification_channels = ["projects/example-project/notificationChannels/1234567890"]
}

run "defaults_are_coherent" {
  assert {
    condition     = google_monitoring_alert_policy.this.combiner == "OR"
    error_message = "combiner default should be OR."
  }

  assert {
    condition     = one(google_monitoring_alert_policy.this.conditions).condition_threshold[0].comparison == "COMPARISON_GT"
    error_message = "comparison default should be COMPARISON_GT so the alert fires when the metric rises above the threshold."
  }

  assert {
    condition     = one(google_monitoring_alert_policy.this.conditions).condition_threshold[0].threshold_value == 0.8
    error_message = "threshold_value default should be 0.8."
  }

  assert {
    condition     = one(google_monitoring_alert_policy.this.conditions).condition_threshold[0].duration == "60s"
    error_message = "duration default should be the seconds string 60s."
  }

  assert {
    condition     = one(google_monitoring_alert_policy.this.conditions).condition_threshold[0].aggregations[0].alignment_period == "60s"
    error_message = "alignment_period default should be the seconds string 60s."
  }

  assert {
    condition     = one(google_monitoring_alert_policy.this.conditions).condition_threshold[0].aggregations[0].per_series_aligner == "ALIGN_MEAN"
    error_message = "per_series_aligner default should be ALIGN_MEAN."
  }
}

# The bug this module class is prone to: an alert policy that is created
# successfully and tells nobody. notification_channels has no default, so
# omitting it is an error rather than a silent empty list; when it is supplied
# it must actually reach the resource.
run "notification_channels_are_attached_to_the_policy" {
  variables {
    notification_channels = [
      "projects/example-project/notificationChannels/1111111111",
      "projects/example-project/notificationChannels/2222222222",
    ]
  }

  assert {
    condition     = length(google_monitoring_alert_policy.this.notification_channels) == 2
    error_message = "notification_channels must be attached to the alert policy."
  }

  assert {
    condition = contains(
      google_monitoring_alert_policy.this.notification_channels,
      "projects/example-project/notificationChannels/2222222222",
    )
    error_message = "every supplied notification channel must be attached to the alert policy."
  }
}

run "overrides_are_passed_through" {
  variables {
    combiner           = "AND"
    comparison         = "COMPARISON_LT"
    duration           = "300s"
    alignment_period   = "120s"
    per_series_aligner = "ALIGN_RATE"
    threshold_value    = 0.25
  }

  assert {
    condition     = google_monitoring_alert_policy.this.combiner == "AND"
    error_message = "combiner override must reach the resource; AND and OR select opposite firing semantics."
  }

  assert {
    condition     = one(google_monitoring_alert_policy.this.conditions).condition_threshold[0].comparison == "COMPARISON_LT"
    error_message = "comparison override must reach the resource."
  }

  assert {
    condition     = one(google_monitoring_alert_policy.this.conditions).condition_threshold[0].duration == "300s"
    error_message = "duration override must reach the resource."
  }

  assert {
    condition     = one(google_monitoring_alert_policy.this.conditions).condition_threshold[0].aggregations[0].alignment_period == "120s"
    error_message = "alignment_period override must reach the resource."
  }

  assert {
    condition     = one(google_monitoring_alert_policy.this.conditions).condition_threshold[0].aggregations[0].per_series_aligner == "ALIGN_RATE"
    error_message = "per_series_aligner override must reach the resource."
  }
}

# Wrong units silently change when an alert fires, so they must be rejected at
# plan time rather than at apply time.
run "rejects_minute_suffixed_duration" {
  variables {
    duration = "5m"
  }

  command = plan

  expect_failures = [var.duration]
}

run "rejects_unitless_duration" {
  variables {
    duration = "120"
  }

  command = plan

  expect_failures = [var.duration]
}

run "rejects_duration_that_is_not_a_whole_minute" {
  variables {
    duration = "90s"
  }

  command = plan

  expect_failures = [var.duration]
}

run "rejects_minute_suffixed_alignment_period" {
  variables {
    alignment_period = "5m"
  }

  command = plan

  expect_failures = [var.alignment_period]
}

run "rejects_sub_minute_alignment_period" {
  variables {
    alignment_period = "30s"
  }

  command = plan

  expect_failures = [var.alignment_period]
}

run "rejects_invalid_comparison" {
  variables {
    comparison = "GREATER_THAN"
  }

  command = plan

  expect_failures = [var.comparison]
}

run "rejects_invalid_combiner" {
  variables {
    combiner = "ANY"
  }

  command = plan

  expect_failures = [var.combiner]
}

run "rejects_invalid_per_series_aligner" {
  variables {
    per_series_aligner = "MEAN"
  }

  command = plan

  expect_failures = [var.per_series_aligner]
}

run "rejects_empty_filter" {
  variables {
    filter = "   "
  }

  command = plan

  expect_failures = [var.filter]
}

run "rejects_empty_notification_channel_id" {
  variables {
    notification_channels = [""]
  }

  command = plan

  expect_failures = [var.notification_channels]
}
