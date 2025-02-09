import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:humm_cli/src/services/files/files_service.dart';
import 'package:humm_cli/src/core/exceptions/exception_handler.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

/// A command that validates the integration of `.arb` files in a project.
///
/// This command performs the following steps:
/// - Identifies all `.arb` files within the current project directory.
/// - Loads the contents of each `.arb` file.
/// - Compares the keys across all `.arb` files to identify missing or inconsistent keys.
/// - Reports any discrepancies in the `.arb` files.
///
/// The command is particularly useful for ensuring that all translations in the
/// project are consistent and complete.
class CheckTranslationsCommand extends Command<int> {
  /// Creates a new instance of [CheckTranslationsCommand].
  ///
  /// Takes a [Logger] instance for logging output during execution.
  CheckTranslationsCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser.addFlag(
      'ci',
      help: 'Indicates that the command is running in a CI environment.',
    );
  }

  @override
  String get description => 'Validates the integration of .arb files in the project.';

  @override
  String get name => 'check_translations';

  final Logger _logger;

  @override
  Future<int> run() async {
    try {
      final FileService fileService = FileService(_logger);
      // Get the current working directory.
      final String currentDir = Directory.current.path;

      // Find all `.arb` files in the project.
      final List<File> arbFiles = await fileService.findArbFiles(currentDir);

      // Exit if no `.arb` files are found.
      if (arbFiles.isEmpty) {
        return ExitCode.software.code;
      }

      final Map<String, Map<String, dynamic>> fileContents = <String, Map<String, dynamic>>{};

      // Load the contents of each `.arb` file.
      for (final File file in arbFiles) {
        final String fileName = path.basename(file.path);
        fileContents[fileName] = await fileService.loadArbFile(file.path);
      }

      bool hasErrors = false;

      // Collect all keys from all `.arb` files.
      final Set<String> allKeys = fileContents.values.expand((Map<String, dynamic> content) => content.keys).toSet();

      // Compare the keys of each `.arb` file with the complete set of keys.
      for (final MapEntry<String, Map<String, dynamic>> entry in fileContents.entries) {
        final String fileName = entry.key;
        final Map<String, dynamic> content = entry.value;

        // Identify missing keys for the current file.
        final Set<String> missingKeys = allKeys.difference(content.keys.toSet());

        if (missingKeys.isNotEmpty) {
          hasErrors = true;
          _logger.err('Missing keys in $fileName:');
          _logger.info(missingKeys.join('\n'));
        } else {
          _logger.info('Missing keys in $fileName: None');
        }
      }

      // Report success or failure based on the validation results.
      if (!hasErrors) {
        _logger.success('ARB file integration status: OK');
        return ExitCode.success.code;
      } else {
        _logger.err('Error: ARB file integration validation failed.');
        return ExitCode.software.code;
      }
    } on Exception catch (e) {
      // Handle any exceptions that occur during execution.
      final ExceptionHandler exceptionHandler = ExceptionHandler(logger: _logger);
      return exceptionHandler.handleException(e);
    }
  }
}
