import 'package:args/command_runner.dart';
import 'package:humm_cli/src/args/common_args/common_flags_handler.dart';
import 'package:humm_cli/src/core/exceptions/exception_handler.dart';
import 'package:humm_cli/src/services/files/changelog_extractor.dart';
import 'package:mason_logger/mason_logger.dart';

class ChangelogCommand extends Command<int> {
  ChangelogCommand({
    required Logger logger,
  }) : _logger = logger {
    CommonFlagsHandler.addCommonFlags(argParser);
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
      final List<String> versionChanges = await ChangelogExtractor.extractCompactForVersion(version);

      _logger.info(versionChanges.join('\n'));

      return ExitCode.success.code;
    } on Exception catch (e) {
      final ExceptionHandler exceptionHandler = ExceptionHandler(logger: _logger);
      return exceptionHandler.handleException(e);
    }
  }
}
