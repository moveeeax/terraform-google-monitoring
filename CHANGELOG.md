# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/). Releases up to v1.1.0 are described
in the [GitHub releases](https://github.com/moveeeax/terraform-google-monitoring/releases).

## [Unreleased]

### Added

- `documentation` input (`content`, `mime_type` defaulting to `text/markdown`,
  optional `subject`) for runbook text in notifications.
- `severity` input (`CRITICAL`, `ERROR` or `WARNING`), unset by default.
- `user_labels` input, empty by default.
- `auto_close` input rendering `alert_strategy.auto_close`, unset by default
  so existing policies plan no change.

[Unreleased]: https://github.com/moveeeax/terraform-google-monitoring/compare/v1.1.0...HEAD
