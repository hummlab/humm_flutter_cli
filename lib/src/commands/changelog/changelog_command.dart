import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:humm_cli/src/core/exceptions/exception_handler.dart';
import 'package:humm_cli/src/core/exceptions/exceptions.dart';
import 'package:mason_logger/mason_logger.dart';

class ChangelogCommand extends Command<int> {
  ChangelogCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser.addFlag(
      'ci',
      help: 'CI helper',
      hide: true,
    );
  }

  @override
  String get description => 'Gets changelog for a specific version';

  @override
  String get name => 'changelog';

  final Logger _logger;

  @override
  Future<int> run() async {
    try {
      if (argResults!.rest.isEmpty) {
        throw const FormatException('Version argument is required');
      }

      final String version = argResults!.rest.first;
      final File changelog = File('CHANGELOG.md');

      if (!changelog.existsSync()) {
        throw NoChangelogFileFoundException();
      }

      final List<String> changelogContent = changelog.readAsLinesSync();
      final List<String> versionChanges = <String>[];
      bool isVersionFound = false;
      bool isCollecting = false;
      for (final String line in changelogContent) {
        if (line.contains('# $version [')) {
          isVersionFound = true;
          isCollecting = true;
          versionChanges.add(line);
          continue;
        }

        if (isCollecting && line.startsWith('# ')) {
          break;
        }

        if (isCollecting && line.isNotEmpty) {
          versionChanges.add(line);
        }
      }

      if (!isVersionFound) {
        _logger.err('No changelog found for version $version');
        return ExitCode.noInput.code;
      }

      _logger.info('Changelog for version $version:\n');
      _logger.info(versionChanges.join('\n'));

      return ExitCode.success.code;
    } on Exception catch (e) {
      final ExceptionHandler exceptionHandler = ExceptionHandler(logger: _logger);
      return exceptionHandler.handleException(e);
    }
  }
}
