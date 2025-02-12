import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:humm_cli/src/core/exceptions/exception_handler.dart';
import 'package:humm_cli/src/core/exceptions/exceptions.dart';
import 'package:humm_cli/src/core/environment/environment_config.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';

/// A command for sending notifications to Slack.
///
/// This command sends a notification to a Slack channel using a configured webhook URL.
/// It can either send a custom message or the changelog related to the current project version.
///
/// The `notify_slack` command accepts the following options:
/// - `--ci`: Indicates whether the command is running in a Continuous Integration (CI) environment.
/// - `--message`: Allows a custom message to be sent to Slack.
/// - `--appName`: The application name for which the Slack webhook is configured (required).
///
/// Example usage:
/// ```dart
/// await runner.run(['notify_slack', '--appName', 'myApp', '--message', 'Build completed']);
/// ```
class NotifySlackCommand extends Command<int> {
  final Logger _logger;

  NotifySlackCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addFlag(
        'ci',
        help: 'CI helper',
      )
      ..addOption(
        'message',
        help: 'Add custom message',
      )
      ..addOption(
        'appName',
        help: 'Application name (required)',
        mandatory: true,
      )
      ..addOption('messageWithChangelog',
          help: 'With this flag set to true changelog will be send with custom message.');
  }

  @override
  String get description => 'Sends a notification to Slack';

  @override
  String get name => 'notify_slack';

  /// Executes the Slack notification command.
  ///
  /// This method sends either a custom message or the changelog related to the current version
  /// to the Slack channel associated with the provided application name.
  ///
  /// If the `--message` flag is provided, it sends the specified message. Otherwise,
  /// it checks for the version in the `pubspec.yaml` file and the corresponding changes in
  /// the `CHANGELOG.md` file, sending those to Slack.
  ///
  /// In case of an error, the method handles exceptions using [ExceptionHandler].
  ///
  /// Returns an [ExitCode] indicating the success or failure of the operation.
  @override
  Future<int> run() async {
    try {
      final String appName = argResults!['appName'] as String;

      // Check if any Slack webhooks are configured
      if (!EnvironmentConfig.hasAnyWebhooks(WebhookApp.slack)) {
        throw NoWebhooksConfiguredException(
          'No webhooks configured. Required format: SLACK_WEBHOOK_APPNAME',
        );
      }

      // Retrieve the webhook URL for the specified application
      final String? webhook = EnvironmentConfig.getWebhook(
        appName: appName,
        app: WebhookApp.slack,
      );
      if (webhook == null) {
        _logger.err('Available apps: ${EnvironmentConfig.getAvailableApps(WebhookApp.slack).join(", ")}');
        throw WebhookNotFoundException('Webhook not found for: $appName');
      }

      final String? message = argResults?['message'];
      final bool sendCustomMessageWithChangelog = argResults?['messageWithChangelog'] == "true";

      // If a custom message is provided, send it to Slack
      if (message != null && !sendCustomMessageWithChangelog) {
        _logger.info('Sending message: "$message"');
        await http.post(
          Uri.parse(webhook),
          headers: <String, String>{'Content-Type': 'application/json'},
          body: json.encode(<String, String>{'text': message}),
        );
        _logger.success('Message sent');
        return ExitCode.success.code;
      }

      // If no custom message, send the changelog related to the current version
      final File pubspecFile = File('pubspec.yaml');
      if (!(await pubspecFile.exists())) {
        throw NoPubspecFileFoundException();
      }

      final List<String> pubspecContent = await pubspecFile.readAsLines();
      final String wantedLine = pubspecContent.firstWhere(
        (String line) => line.startsWith('version'),
      );
      final String currentVersion = wantedLine.replaceAll('version:', '').trim().split('+').first;

      final File changelog = File('CHANGELOG.md');
      final List<String> changelogContent = changelog.readAsLinesSync();

      // Check if the changelog contains the current version
      if (!changelogContent.first.contains(currentVersion)) {
        _logger.err('No changes for version $currentVersion');
        return ExitCode.ioError.code;
      }

      // Collect the changelog entries related to the current version
      final List<String> changesRelatedToVersion = <String>[];
      changesRelatedToVersion.add(changelogContent.first);

      for (String line in changelogContent.skip(1)) {
        if (line.contains('#')) break;
        changesRelatedToVersion.add(line);
      }

      _logger.info('Sending changelog...');
      String formattedChangelog = '${changesRelatedToVersion.join('\n')}\n';
      if (message != null && sendCustomMessageWithChangelog) {
        _logger.info('Adding custom message to changelog $message');
        formattedChangelog = '$formattedChangelog\n$message';
      }
      // Send the changelog to Slack
      await http.post(
        Uri.parse(webhook),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: json.encode(<String, String>{'text': formattedChangelog}),
      );

      _logger.success('Changelog sent');
      return ExitCode.success.code;
    } on Exception catch (e) {
      final ExceptionHandler exceptionHandler = ExceptionHandler(logger: _logger);
      return exceptionHandler.handleException(e);
    }
  }
}
