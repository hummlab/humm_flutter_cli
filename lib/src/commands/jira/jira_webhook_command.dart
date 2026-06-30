import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:humm_cli/src/args/common_args/common_flags_handler.dart';
import 'package:humm_cli/src/core/environment/environment_config.dart';
import 'package:humm_cli/src/core/exceptions/exception_handler.dart';
import 'package:humm_cli/src/core/exceptions/exceptions.dart';
import 'package:humm_cli/src/services/files/changelog_extractor.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';

/// Sends a changelog to a Jira webhook.
class JiraSendChangelogWebookCommand extends Command<int> {
  final Logger _logger;

  JiraSendChangelogWebookCommand({
    required Logger logger,
  }) : _logger = logger {
    CommonFlagsHandler.addCommonFlags(argParser);
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

    final String releaseVersion = argResults!.rest.first;

    final String? jiraWebhookUrl = EnvironmentConfig.getWebhook(app: WebhookApp.jira);

    if (jiraWebhookUrl == null || jiraWebhookUrl.isEmpty) {
      throw NoWebhooksConfiguredException('No Jira webhook found.');
    }

    final String? jiraWebhookToken = EnvironmentConfig.getAuthToken(app: WebhookAuthTokens.jira);

    if (jiraWebhookToken == null || jiraWebhookToken.isEmpty) {
      throw NoAuthTokenException('Jira token not provided.');
    }

    final String changelog = (await ChangelogExtractor.extractCompactForVersion(releaseVersion)).join('\n');

    _logger.info('Raw changelog output:');
    _logger.info(changelog);

    final List<String> taskNumbers = _extractTaskNumbers(changelog);

    _logger.info('Found tasks: $taskNumbers');

    if (taskNumbers.isEmpty) {
      _logger.err('No task numbers found in changelog, Exiting...');
      return ExitCode.noInput.code;
    }

    // Format the changelog for readability in Jira
    // Keep this simple to avoid breaking the regex matching
    final String formattedChangelog = changelog;

    // Prepare the JSON payload
    final Map<String, dynamic> payload = <String, dynamic>{
      'issues': taskNumbers,
      'data': <String, String>{
        'changelog': formattedChangelog,
        'releaseVersion': releaseVersion,
      }
    };

    final String jsonPayload = jsonEncode(payload);
    _logger.info('Payload: $jsonPayload');
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

  List<String> _extractTaskNumbers(String text) {
    final Set<String> taskNumbers = <String>{};

    final RegExp jiraPattern = RegExp(r'[A-Z]+-\d+');
    final Iterable<RegExpMatch> jiraMatches = jiraPattern.allMatches(text);
    for (final RegExpMatch match in jiraMatches) {
      taskNumbers.add(match.group(0)!);
    }

    final RegExp bracketPattern = RegExp(r'\[(\d+)\]');
    final Iterable<RegExpMatch> bracketMatches = bracketPattern.allMatches(text);
    for (final RegExpMatch match in bracketMatches) {
      taskNumbers.add(match.group(1)!);
    }

    return taskNumbers.toList();
  }
}
