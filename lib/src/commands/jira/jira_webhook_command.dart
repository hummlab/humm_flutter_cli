import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:humm/src/core/environment/environment_config.dart';
import 'package:humm/src/core/exceptions/exception_handler.dart';
import 'package:humm/src/core/exceptions/exceptions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:http/http.dart' as http;

/// Sends a changelog to a Jira webhook.
class JiraSendChangelogWebookCommand extends Command<int> {
  final Logger _logger;

  JiraSendChangelogWebookCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addFlag(
        'ci',
        help: 'CI helper',
      );
  }

  @override
  String get description => 'Sends a changelog to Jira webhook';

  @override
  String get name => 'jira_changelog';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      throw const FormatException('Version argument is required');
    }

    String releaseVersion = argResults!.rest.first;

    if (!EnvironmentConfig.hasAnyWebhooks(WebhookApp.jira)) {
      throw NoWebhooksConfiguredException('No Jira webhooks configured.');
    }

    final String? jiraWebhookUrl = EnvironmentConfig.getWebhook(app: WebhookApp.jira);

    if (jiraWebhookUrl == null || jiraWebhookUrl.isEmpty) {
      throw NoWebhooksConfiguredException('No Jira webhook found.');
    }

    String? jiraWebhookToken = EnvironmentConfig.getAuthToken(app: WebhookAuthTokens.jira);

    if (jiraWebhookToken == null || jiraWebhookToken.isEmpty) {
      throw NoAuthTokenException('Jira token not provided.');
    }

    // Run the changelog command
    ProcessResult result = await Process.run('humm', <String>['changelog', releaseVersion]);

    String changelog = result.stdout.toString().trim();
    _logger.info(changelog);

    if (result.exitCode != 0) {
      changelog += "\nError: " + result.stderr.toString().trim();
    }

    // Extract issue numbers from changelog
    final RegExp regex = RegExp(r'\[(\d+)\]');
    final Iterable<RegExpMatch> matches = regex.allMatches(changelog);
    final List<String> taskNumbers = matches.map((RegExpMatch match) => match.group(1)!).toList();

    // Prepare the JSON payload
    Map<String, dynamic> payload = <String, dynamic>{
      'issues': taskNumbers,
      'data': <String, String>{
        'changelog': changelog,
        'releaseVersion': releaseVersion,
      }
    };

    String jsonPayload = jsonEncode(payload);

    try {
      final http.Response response = await http.post(
        Uri.parse(jiraWebhookUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Automation-Webhook-Token': jiraWebhookToken,
        },
        body: jsonPayload,
      );

      _logger.info('Response status: ${response.statusCode}');
      _logger.info('Response body: ${response.body}');
    } on Exception catch (e) {
      _logger.err('Error sending data to Jira Automation: $e');
      final ExceptionHandler exceptionHandler = ExceptionHandler(logger: _logger);
      return exceptionHandler.handleException(e);
    }

    return ExitCode.success.code;
  }
}
