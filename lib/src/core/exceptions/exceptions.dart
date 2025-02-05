/// Exception thrown when no `pubspec.yaml` file is found.
class NoPubspecFileFoundException implements Exception {}

/// Exception thrown when no `changelog` file is found.
class NoChangelogFileFoundException implements Exception {}

/// Exception thrown when an invalid version is provided.
class WrongVersionProvidedException implements Exception {}

/// Exception thrown when the build version in `pubspec.yaml` is incorrect.
class WrongBuildVersionInPubspecException implements Exception {}

/// Exception thrown when the build version provided from the command line is incorrect.
class WrongBuildVersionFromCommandLineException implements Exception {}

/// Exception thrown when no webhooks are configured.
class NoWebhooksConfiguredException implements Exception {
  final String message;

  NoWebhooksConfiguredException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when no auth tokens are configured.
class NoAuthTokenException implements Exception {
  final String message;

  NoAuthTokenException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when a specified webhook is not found.
class WebhookNotFoundException implements Exception {
  final String message;

  WebhookNotFoundException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when an invalid selection is made.
class InvalidSelectionException implements Exception {
  final String message;

  InvalidSelectionException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when no AWS distributions are configured.
class NoAwsDistributionsConfiguredException implements Exception {
  final String message;

  NoAwsDistributionsConfiguredException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when a specified AWS distribution is not found.
class AwsDistributionNotFoundException implements Exception {
  final String message;

  AwsDistributionNotFoundException(this.message);

  @override
  String toString() => message;
}
