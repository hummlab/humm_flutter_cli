import 'dart:io';

import 'package:humm/src/core/exceptions.dart';
import 'package:mason_logger/mason_logger.dart';

/// A class responsible for handling exceptions and logging error messages.
class ExceptionHandler {
  final Logger _logger;

  /// Creates an instance of [ExceptionHandler] with the provided [logger].
  ExceptionHandler({required Logger logger}) : _logger = logger;

  /// Handles an exception by logging the appropriate error message and returning an exit code.
  ///
  /// The method uses a [switch] statement to determine the type of exception and provides a
  /// corresponding error message. It logs the error message using the provided [logger] and
  /// returns an appropriate exit code based on the exception type.
  ///
  /// [exception] is the exception that needs to be handled.
  ///
  /// Returns an [int] representing the exit code. The default exit code is `ExitCode.software.code`.
  ///
  /// Example usage:
  /// ```dart
  /// final handler = ExceptionHandler(logger: logger);
  /// int exitCode = handler.handleException(e);
  /// ```
  int handleException(Exception exception) {
    int errorCode = ExitCode.software.code;

    final String message = switch (exception.runtimeType) {
      NoWebhooksConfiguredException => (exception as NoWebhooksConfiguredException).message,
      WebhookNotFoundException => (exception as WebhookNotFoundException).message,
      InvalidSelectionException => (exception as InvalidSelectionException).message,
      NoPubspecFileFoundException => 'No pubspec.yaml file found. Are you in the project\'s main directory?',
      FormatException => 'Invalid version format in pubspec.yaml.',
      NoChangelogFileFoundException => 'No CHANGELOG.md file found.',
      WrongVersionProvidedException => 'The provided version has an invalid format',
      WrongBuildVersionInPubspecException => 'Problem with the build number in pubspec',
      WrongBuildVersionFromCommandLineException => 'Invalid build version',
      FileSystemException => 'File system error: $exception',
      NoAwsDistributionsConfiguredException => (exception as NoAwsDistributionsConfiguredException).message,
      AwsDistributionNotFoundException => (exception as AwsDistributionNotFoundException).message,
      _ => 'An unhandled error occurred: $exception',
    };

    _logger.err(message);
    return errorCode;
  }
}
