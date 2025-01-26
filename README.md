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
humm release

# Options
humm release --set-version $version        # Set a specific version (default: increment by 1)
humm release --branch $branch              # Specify branch (default: develop)
humm release --tag-prefix $tag_prefix      # Add a custom tag prefix
humm release --set-bn $build_number        # Set a specific build number

```

### Changelog

```sh
# Generate production changelog
humm prod_changelog --version $version # Generate changelog for a specific version

# Get changelog for a specific version
humm changelog $version                # Example: humm changelog 7.11.2
```

### Slack Notifications

```sh
# Notify Slack about a changelog
humm notify_slack --appName PROJECT_NAME

# Notify Slack with a custom message
humm notify_slack --appName PROJECT_NAME --message "Custom message"

# Notify Slack about an error
humm notify_slack_error --appName PROJECT_NAME
```

### Check translations

```sh
# Verify all ARB translation files in the project
humm check_translations
```

### Check strings

```sh
# Find and display all static strings in widgets
humm check_strings
```

### Cache Invalidation

```sh
# Invalidate AWS CloudFront cache
humm invalidate
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

## Example Git Flow

##### Branches
```sh
main: Production branch - contains current prod version.
develop: Staging branch.
releases/<version>: Release branches, e.g., releases/1.4.x, releases/1.4.x.
# Or in cases of mono repos with multiple projects
releases/<component>/<version>: Release branches, e.g., releases/appName/1.4.x, releases/appName2/3.5.x.
```

##### How It Works
```sh
Developers should work on a release branch, such as releases/1.4.x or releases/appName/1.4.x.

Once the work is ready, the release branch is merged into develop. The workflow then automates the following steps:

Trigger CI/CD Pipeline on Changes to develop:
If your CI/CD pipeline is configured to release on changes to the develop branch (e.g., see examples/example-ci-cd-develop-trigger.yaml), it will:

Update the pubspec.yaml file with the new version.
Update the changelog automatically.
Create a version tag to trigger the release workflow (see an example for tag triggers in examples/example-tag-trigger.yaml).
Create or Update Release Branches:
Using the GitHub Actions workflow (e.g., examples/example-create-or-update-branch.yaml):

The action detects the merged release branch and determines the next version.
If a branch for the next version does not exist (e.g., releases/1.5.x or releases/appName/1.5.x), the workflow creates the new release branch and updates the pubspec.yaml file with the next version. The new branch is then pushed to the repository.
If the next branch already exists (e.g., releases/1.5.x), the workflow creates pull requests from develop to all higher-version branches (e.g., releases/1.6.x, releases/1.7.x) to propagate changes.
Manual Conflict Resolution:
Developers must manually review and resolve any conflicts in the pull requests created for higher-version branches before merging them.
```
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
