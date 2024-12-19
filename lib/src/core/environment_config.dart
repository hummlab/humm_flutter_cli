import 'dart:io';

/// A class that provides access to environment variables related to Slack webhooks and cloud distributions.
///
/// This class retrieves and manages environment variables used for configuring webhooks for different
/// applications and obtaining cloud distribution information. All variables are expected to be prefixed
/// with `SLACK_WEBHOOK_` for webhooks and use the key `CLOUD_DISTRIBUTION` for cloud distribution details.
class EnvironmentConfig {
  // Prefix for environment variables related to Slack webhooks
  static const _webhookPrefix = 'SLACK_WEBHOOK_';

  // Key for the environment variable that stores cloud distribution information
  static const cloudDistributionKey = 'CLOUD_DISTRIBUTION';

  /// Retrieves the Slack webhook URL for a given application name.
  ///
  /// This method constructs the environment variable key by appending the provided [appName] to the
  /// `SLACK_WEBHOOK_` prefix and returns the corresponding value from the environment.
  ///
  /// If the environment variable is not set, it returns `null`.
  ///
  /// [appName] is the name of the application for which the webhook URL is needed.
  ///
  /// Returns a [String?] representing the Slack webhook URL for the application or `null` if not found.
  ///
  /// Example usage:
  /// ```dart
  /// final webhookUrl = EnvironmentConfig.getSlackWebhook('myApp');
  /// ```
  static String? getSlackWebhook(String appName) {
    final webhookKey = '$_webhookPrefix${appName.toUpperCase()}';
    return Platform.environment[webhookKey];
  }

  /// Retrieves a list of all available application names that have Slack webhooks configured.
  ///
  /// This method filters the environment variable keys to those starting with the `SLACK_WEBHOOK_` prefix,
  /// then extracts and returns the application names by removing the prefix.
  ///
  /// Returns a [List<String>] containing the names of all applications with configured webhooks.
  ///
  /// Example usage:
  /// ```dart
  /// final availableApps = EnvironmentConfig.getAvailableApps();
  /// ```
  static List<String> getAvailableApps() {
    return Platform.environment.keys
        .where((key) => key.startsWith(_webhookPrefix))
        .map((key) => key.replaceAll(_webhookPrefix, ''))
        .toList();
  }

  /// Checks if any Slack webhooks are configured in the environment variables.
  ///
  /// This method checks if there are any environment variables whose keys start with the `SLACK_WEBHOOK_`
  /// prefix, indicating that Slack webhooks are configured for one or more applications.
  ///
  /// Returns a [bool] indicating whether any webhooks are configured.
  ///
  /// Example usage:
  /// ```dart
  /// final hasWebhooks = EnvironmentConfig.hasAnyWebhooks();
  /// ```
  static bool hasAnyWebhooks() {
    return Platform.environment.keys.any((key) => key.startsWith(_webhookPrefix));
  }

  /// Retrieves the cloud distribution information from the environment.
  ///
  /// This method returns the value of the environment variable with the key `CLOUD_DISTRIBUTION`, which
  /// represents cloud distribution information. If the environment variable is not set, it returns `null`.
  ///
  /// Returns a [String?] containing the cloud distribution information or `null` if not found.
  ///
  /// Example usage:
  /// ```dart
  /// final cloudDistribution = EnvironmentConfig.getCloudDistribution();
  /// ```
  static String? getCloudDistribution() {
    return Platform.environment[cloudDistributionKey];
  }
}
