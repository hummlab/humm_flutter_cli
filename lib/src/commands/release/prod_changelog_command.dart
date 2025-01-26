import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:humm/src/core/exception_handler.dart';
import 'package:humm/src/commands/release/parsers/parse_prod_changelog_arguments.dart';

import 'package:mason_logger/mason_logger.dart';

/// A command to generate and log production changelog details.
///
/// This command processes the `CHANGELOG.md` file to extract changes related to a
/// specified version. It ensures that the changelog contains changes for the provided
/// version and formats the changes for further use.
///
/// Options:
/// - `--ci`: Indicates that the command is running in a CI environment.
/// - `--version`: Specifies the version to process in the changelog.
class ProdChangelogCommand extends Command<int> {
  /// Creates a new instance of [ProdChangelogCommand].
  ///
  /// Requires a [Logger] to handle logging output during the command's execution.
  ProdChangelogCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser.addFlag(
      'ci',
      help: 'Indicates that the command is running in a CI environment.',
    );
    argParser.addOption(
      'version',
      help: 'Specifies the version to process in the changelog.',
    );
  }

  @override
  String get description => 'Processes and logs production changelog details.';

  @override
  String get name => 'prod_changelog';

  final Logger _logger;

  @override
  Future<int> run() async {
    try {
      /// Parses arguments and retrieves the specified version.
      final String currentVersion = await parseProdChangeLogArguments(argResults!);

      /// Validates the existence of `CHANGELOG.md`.
      final File changelog = File('CHANGELOG.md');
      if (!changelog.existsSync()) {
        _logger.err('CHANGELOG.md does not exist.');
        return ExitCode.noInput.code;
      }

      /// Reads the content of the changelog file.
      final List<String> changelogContent = changelog.readAsLinesSync();
      if (changelogContent.isEmpty) {
        _logger.err('CHANGELOG.md is empty.');
        return ExitCode.noInput.code;
      }

      /// Checks if the changelog already contains the specified version's changes.
      if (changelogContent.first.contains(currentVersion)) {
        _logger.err('There are no new changes for version $currentVersion.');
        return ExitCode.ioError.code;
      }

      final List<String> changesRelatedToVersion = <String>[];

      _logger.info('Reading changes...');

      /// Extracts changes related to the specified version.
      for (String line in changelogContent.skip(1)) {
        if (line.contains('# $currentVersion [') || line.contains('# $currentVersion+')) {
          break;
        }

        if (line.contains(RegExp(r'\#.*\['))) {
          continue;
        }

        if (line.contains(RegExp(r'^- \[dev-'))) {
          continue;
        }

        changesRelatedToVersion.add(line);
      }

      _logger.success('Changes have been read.');

      changesRelatedToVersion.removeWhere((String element) => element.isEmpty);
      final List<String> finalChangelog = <String>[];

      _logger.info('Creating final changelog...');

      /// Cleans and formats the extracted changes.
      for (String line in changesRelatedToVersion) {
        line = line.replaceAll(RegExp(r'\[[a-z]+\]'), '');
        line = line.replaceAll(RegExp(r'\[[0-9]+\]'), '');
        finalChangelog.add(line);
      }

      _logger.success('Logging final changelog:\n');

      _logger.info('${finalChangelog.join('\n')}\n');

      return ExitCode.success.code;
    } on Exception catch (e) {
      /// Handles exceptions during the execution.
      final ExceptionHandler exceptionHandler = ExceptionHandler(logger: _logger);
      return exceptionHandler.handleException(e);
    }
  }
}
