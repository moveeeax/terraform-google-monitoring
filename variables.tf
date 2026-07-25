variable "project_id" {
  description = "ID of the project in which to create the alert policy."
  type        = string
}

variable "display_name" {
  description = "Display name of the alert policy."
  type        = string
}

variable "combiner" {
  description = <<-EOT
    How to combine the conditions: AND, OR, AND_WITH_MATCHING_RESOURCE. This
    module creates exactly one condition, so the value has no practical effect
    today; it is exposed so the policy reads correctly if conditions are added.
  EOT
  type        = string
  default     = "OR"

  validation {
    condition     = contains(["AND", "OR", "AND_WITH_MATCHING_RESOURCE"], var.combiner)
    error_message = "combiner must be one of AND, OR or AND_WITH_MATCHING_RESOURCE."
  }
}

variable "condition_display_name" {
  description = "Display name of the metric threshold condition."
  type        = string
  default     = "metric threshold"
}

variable "filter" {
  description = "Monitoring filter selecting the time series to evaluate."
  type        = string
  default     = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""

  validation {
    condition     = length(trimspace(var.filter)) > 0
    error_message = "filter must not be empty."
  }
}

variable "threshold_value" {
  description = "Threshold the aligned metric must cross to trigger the alert."
  type        = number
  default     = 0.8
}

variable "comparison" {
  description = "Comparison operator used against the threshold."
  type        = string
  default     = "COMPARISON_GT"

  validation {
    condition = contains([
      "COMPARISON_GT",
      "COMPARISON_GE",
      "COMPARISON_LT",
      "COMPARISON_LE",
      "COMPARISON_EQ",
      "COMPARISON_NE",
    ], var.comparison)
    error_message = "comparison must be one of COMPARISON_GT, COMPARISON_GE, COMPARISON_LT, COMPARISON_LE, COMPARISON_EQ or COMPARISON_NE."
  }
}

variable "duration" {
  description = <<-EOT
    Duration the condition must hold before alerting, as a seconds string such
    as "60s". Cloud Monitoring only accepts whole minutes here, so the value
    must be a multiple of 60 seconds.
  EOT
  type        = string
  default     = "60s"

  validation {
    condition     = can(regex("^[0-9]+s$", var.duration))
    error_message = "duration must be a whole number of seconds with an \"s\" suffix, e.g. \"60s\". Values like \"5m\", \"120\" or \"1.5s\" are rejected by Cloud Monitoring."
  }

  validation {
    condition     = can(regex("^[0-9]+s$", var.duration)) && tonumber(trimsuffix(var.duration, "s")) % 60 == 0
    error_message = "duration must be a multiple of 60 seconds, e.g. \"0s\", \"60s\", \"300s\"."
  }
}

variable "alignment_period" {
  description = <<-EOT
    Alignment period for the condition aggregation, as a seconds string such as
    "60s". This is the window each data point is aligned over and it directly
    changes when the alert fires, so the unit matters. Must be at least 60s.
  EOT
  type        = string
  default     = "60s"

  validation {
    condition     = can(regex("^[0-9]+s$", var.alignment_period))
    error_message = "alignment_period must be a whole number of seconds with an \"s\" suffix, e.g. \"60s\". Values like \"5m\" or \"60\" are rejected by Cloud Monitoring."
  }

  validation {
    condition     = can(regex("^[0-9]+s$", var.alignment_period)) && tonumber(trimsuffix(var.alignment_period, "s")) >= 60
    error_message = "alignment_period must be at least 60 seconds."
  }
}

variable "per_series_aligner" {
  description = "Aligner applied to each time series before comparison, e.g. ALIGN_MEAN or ALIGN_RATE."
  type        = string
  default     = "ALIGN_MEAN"

  validation {
    condition     = can(regex("^ALIGN_[A-Z0-9_]+$", var.per_series_aligner))
    error_message = "per_series_aligner must be an ALIGN_* value such as ALIGN_MEAN, ALIGN_RATE or ALIGN_MAX."
  }
}

variable "notification_channels" {
  description = <<-EOT
    IDs of the notification channels alerted when the policy fires. Required and
    intentionally has no default: a policy with no channels raises incidents that
    nobody is told about. Pass [] to opt into that deliberately.
  EOT
  type        = list(string)

  validation {
    condition     = alltrue([for c in var.notification_channels : length(trimspace(c)) > 0])
    error_message = "notification_channels must not contain empty strings."
  }
}
