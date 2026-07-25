# terraform-google-monitoring

Terraform module that manages a [Google Cloud](https://cloud.google.com/)
Cloud Monitoring alert policy (`google_monitoring_alert_policy`). It creates a
single metric-threshold condition with configurable filter, comparison and
duration.

## Usage

```hcl
resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Alerting email"
  type         = "email"

  labels = {
    email_address = var.notification_email
  }
}

module "monitoring" {
  source = "github.com/moveeeax/terraform-google-monitoring"

  project_id      = var.project_id
  display_name    = "High CPU utilization"
  filter          = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
  threshold_value = 0.8
  comparison      = "COMPARISON_GT"
  duration        = "120s"

  notification_channels = [google_monitoring_notification_channel.email.id]
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Notes

**Notification channels are required.** `notification_channels` has no default
on purpose. An alert policy with no channels still opens incidents in the Cloud
Monitoring console, but nobody is paged or emailed — the policy applies cleanly
and does nothing useful. Pass `[]` if that is genuinely what you want.

**Durations are seconds strings.** `duration` and `alignment_period` are Cloud
Monitoring duration strings and must end in `s`. Cloud Monitoring only accepts
whole minutes for `duration`, and `alignment_period` must be at least `60s`.
A wrong unit does not fail loudly — it silently changes *when* the alert fires
— so both are validated at plan time. `"5m"`, `"120"` and `"90s"` are rejected.

**Secrets in notification channels.** This module does not create notification
channels; it only attaches channel IDs you pass in. If you create a channel
whose configuration carries a secret — a Slack or PagerDuty webhook URL with an
embedded token, for example — put it in the provider's `sensitive_labels` block
rather than `labels`. Values in `labels` are stored and rendered in plaintext.

**`combiner` and the single condition.** This module creates exactly one
condition, so `AND` and `OR` behave identically today. The variable is exposed
so the policy reads correctly and stays forward-compatible.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| google    | >= 5.0   |

## Inputs

| Name                     | Description                                                        | Type           | Default              | Required |
|--------------------------|--------------------------------------------------------------------|----------------|----------------------|:--------:|
| `project_id`             | ID of the project in which to create the policy.                   | `string`       | n/a                  |   yes    |
| `display_name`           | Display name of the alert policy.                                  | `string`       | n/a                  |   yes    |
| `notification_channels`  | Channel IDs alerted when the policy fires. Pass `[]` to opt out.   | `list(string)` | n/a                  |   yes    |
| `combiner`               | `AND`, `OR` or `AND_WITH_MATCHING_RESOURCE`.                       | `string`       | `"OR"`               |    no    |
| `condition_display_name` | Display name of the condition.                                     | `string`       | `"metric threshold"` |    no    |
| `filter`                 | Monitoring filter selecting the time series.                       | `string`       | CPU utilization      |    no    |
| `threshold_value`        | Threshold the aligned metric must cross.                           | `number`       | `0.8`                |    no    |
| `comparison`             | `COMPARISON_GT`/`GE`/`LT`/`LE`/`EQ`/`NE`.                          | `string`       | `"COMPARISON_GT"`    |    no    |
| `duration`               | Seconds string; must be a multiple of 60, e.g. `"300s"`.           | `string`       | `"60s"`              |    no    |
| `alignment_period`       | Seconds string for the aggregation window; minimum `"60s"`.        | `string`       | `"60s"`              |    no    |
| `per_series_aligner`     | `ALIGN_*` aligner applied before comparison.                       | `string`       | `"ALIGN_MEAN"`       |    no    |

## Outputs

| Name   | Description                        |
|--------|------------------------------------|
| `id`   | Identifier of the alert policy.   |
| `name` | Resource name of the alert policy.|

## Tests

`tests/` holds a `terraform test` suite that runs against a mocked provider —
no credentials, no network, no API calls:

```sh
terraform init -backend=false
terraform test
```

The suite needs Terraform (or OpenTofu) >= 1.7 for `mock_provider`. That is a
requirement of the tests only; the module itself still supports >= 1.5.

## License

[MIT](LICENSE)
