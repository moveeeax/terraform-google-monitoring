resource "google_monitoring_alert_policy" "this" {
  project      = var.project_id
  display_name = var.display_name
  combiner     = var.combiner
  severity     = var.severity

  # An empty map is sent as null so a policy without labels plans no diff.
  user_labels = length(var.user_labels) > 0 ? var.user_labels : null

  conditions {
    display_name = var.condition_display_name

    condition_threshold {
      filter          = var.filter
      comparison      = var.comparison
      threshold_value = var.threshold_value
      duration        = var.duration

      aggregations {
        alignment_period   = var.alignment_period
        per_series_aligner = var.per_series_aligner
      }
    }
  }

  dynamic "documentation" {
    for_each = var.documentation == null ? [] : [var.documentation]
    content {
      content   = documentation.value.content
      mime_type = documentation.value.mime_type
      subject   = documentation.value.subject
    }
  }

  # auto_close = null omits the block and leaves incident closing to the API.
  dynamic "alert_strategy" {
    for_each = var.auto_close == null ? [] : [var.auto_close]
    content {
      auto_close = alert_strategy.value
    }
  }

  notification_channels = var.notification_channels
}
