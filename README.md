## humm

Humm Flutter CLI package - a tool for project management.

---

## Getting Started 🚀

To activate the CLI, run this command in the project's root folder:

```sh
dart pub global activate --source path .
```

## Usage

### Release

```sh
# Basic release command
$ humm_cli release

# Release command options
$ humm_cli release --set-version $version # Default increases by 1
$ humm_cli release --branch $branch # Default is develop
$ humm_cli release --tag-prefix $tag
$ humm_cli release --set-bn $build_number # Set specific build number
```

### Changelog

```sh
# Production changelog command
$ humm_cli prod_changelog --version $version # Set version
```

### Slack Notifications

```sh
# Send changelog to Slack
$ humm_cli notify_slack --appName PROJECT_NAME

# Send custom message to Slack
$ humm_cli notify_slack --appName PROJECT_NAME --message "message_content"

# Send error notification
$ humm_cli notify_slack_error --appName PROJECT_NAME
```

### Cache Invalidation

```sh
# Invalidate CloudFront cache
$ humm_cli invalidate
```

---

## Requirements

- Dart SDK >=3.0.0
- AWS CLI access (for CloudFront commands)
- Configured environment variables (for notifications and cache invalidation)

## Environment Variables

The following environment variables are required for different functionalities:

### Slack Notifications
Configure webhooks for each project:
```sh
SLACK_WEBHOOK_PROJECT1=https://hooks.slack.com/services/...
SLACK_WEBHOOK_PROJECT2=https://hooks.slack.com/services/...
```

### AWS CloudFront Invalidation
```sh
CLOUD_DISTRIBUTION=E1234567890ABCD
```

## Usage in CI/CD (Codemagic example)

```yaml
workflows:
  my-workflow:
    environment:
      vars:
        # Slack webhooks for different projects
        SLACK_WEBHOOK_PROJECT1: $PROJECT1_WEBHOOK
        SLACK_WEBHOOK_PROJECT2: $PROJECT2_WEBHOOK
        # CloudFront distribution
        CLOUD_DISTRIBUTION: $CLOUDFRONT_ID
    
    scripts:
      - name: Send notification
        script: |
          humm notify_slack --appName PROJECT1 --message "Build completed"
      
      - name: Invalidate cache
        script: |
          humm invalidate
```

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis