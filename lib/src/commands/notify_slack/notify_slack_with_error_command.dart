import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:humm/src/core/environment_config.dart';
import 'package:humm/src/core/exception_handler.dart';
import 'package:humm/src/core/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';

/// A command for sending an error notification to Slack.
///
/// This command sends a notification to Slack when an error occurs during the creation
/// of a version of the project. It includes the project name and the version number
/// to inform the team of the failure.
///
/// The `notify_slack_error` command accepts the following options:
/// - `--ci`: Indicates whether the command is running in a Continuous Integration (CI) environment.
/// - `--appName`: The application name for which the Slack webhook is configured (required).
///
/// Example usage:
/// ```dart
/// await runner.run(['notify_slack_error', '--appName', 'myApp']);
/// ```
class NotifySlackWithErrorCommand extends Command<int> {
  final Logger _logger;

  NotifySlackWithErrorCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addFlag(
        'ci',
        help: 'CI helper',
      )
      ..addOption(
        'appName',
        help: 'Application name (required)',
        mandatory: true,
      );
  }

  @override
  String get description => 'Sends an error notification to Slack';

  @override
  String get name => 'notify_slack_error';

  /// Executes the command to send an error notification to Slack.
  ///
  /// This method attempts to send a Slack notification indicating that an error occurred during
  /// the creation of a new version for the specified application. The message includes the
  /// application name and the current version.
  ///
  /// If the `--appName` flag is not provided, or if there are issues with webhooks, it will
  /// throw an exception.
  ///
  /// Returns an [ExitCode] indicating the success or failure of the operation.
  @override
  Future<int> run() async {
    try {
      final appName = argResults!['appName'] as String;

      // Check if any Slack webhooks are configured
      if (!EnvironmentConfig.hasAnyWebhooks()) {
        throw NoWebhooksConfiguredException(
          'No webhooks configured. Required format: SLACK_WEBHOOK_APPNAME',
        );
      }

      // Retrieve the webhook URL for the specified application
      final webhook = EnvironmentConfig.getSlackWebhook(appName);
      if (webhook == null) {
        _logger.err('Available apps: ${EnvironmentConfig.getAvailableApps().join(", ")}');
        throw WebhookNotFoundException('Webhook not found for: $appName');
      }

      // Read the pubspec.yaml file to get the current version
      final File pubspecFile = File('pubspec.yaml');
      final List<String> pubspecContent = await pubspecFile.readAsLines();
      final String wantedLine = pubspecContent.firstWhere(
        (String line) => line.startsWith('version'),
      );
      final String currentVersion = wantedLine.replaceAll('version:', '').trim().split('+').first;

      // Send an error notification to Slack with the version and app name
      await http.post(
        Uri.parse(webhook),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
            {'text': 'Something went wrong during the creation of version: $currentVersion for project: $appName\n'}),
      );

      _logger.success('Error notification sent');
      return ExitCode.success.code;
    } on Exception catch (e) {
      final exceptionHandler = ExceptionHandler(logger: _logger);
      return exceptionHandler.handleException(e);
    }
  }
}
