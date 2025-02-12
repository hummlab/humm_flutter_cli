import 'dart:io';

/// Provides access to environment variables for webhooks and cloud distribution.
///
/// This class manages webhook configurations for different applications
/// and retrieves cloud distribution details from environment variables.
class EnvironmentConfig {
  /// Environment key for cloud distribution information.
  static const String cloudDistributionKey = 'CLOUD_DISTRIBUTION';

  /// Returns the webhook URL for a given app.
  ///
  /// If no webhook is set, it returns `null`.
  ///
  /// [appName] is optional and used when different webhooks exist for different apps.
  static String? getWebhook({
    String? appName,
    required WebhookApp app,
  }) {
    final String webhookKey = '${app.prefix}${appName ?? ''}';
    return Platform.environment[webhookKey];
  }

  static String? getAuthToken({
    String? appName,
    required WebhookAuthTokens app,
  }) {
    return Platform.environment[app.tokenKey];
  }

  /// Returns a list of available apps with configured webhooks.
  ///
  /// Filters environment variables by the given app prefix and extracts app names.
  static List<String> getAvailableApps(WebhookApp app) {
    return Platform.environment.keys
        .where((String key) => key.startsWith(app.prefix))
        .map((String key) => key.replaceAll(app.prefix, ''))
        .toList();
  }

  /// Checks if any webhooks are configured for the given app.
  ///
  /// Returns `true` if at least one environment variable starts with the app's prefix.
  static bool hasAnyWebhooks(WebhookApp app) {
    return Platform.environment.keys
        .any((String key) => key.startsWith(app.prefix));
  }

  /// Returns cloud distribution information from the environment.
  ///
  /// If not set, returns `null`.
  static String? getCloudDistribution() {
    return Platform.environment[cloudDistributionKey];
  }
}

/// Enum representing different webhook types.
enum WebhookApp {
  slack('SLACK_WEBHOOK_'),
  jira('JIRA_WEBHOOK_URL');

  final String prefix;

  const WebhookApp(this.prefix);
}

enum WebhookAuthTokens {
  jira('JIRA_WEBHOOK_TOKEN');

  final String tokenKey;

  const WebhookAuthTokens(this.tokenKey);
}
