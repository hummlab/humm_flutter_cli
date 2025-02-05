import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:humm/src/commands/_commands.dart';
import 'package:humm/src/commands/notify_slack/notify_slack_with_error_command.dart';
import 'package:humm/src/commands/release/prod_changelog_command.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

const String executableName = 'humm';
const String packageName = 'humm';
const String description = 'Humm cli package';

/// {@template humm_command_runner}
/// Custom [CommandRunner] for the Humm CLI.
///
/// Provides the base functionality for executing commands, parsing arguments,
/// and handling errors.
/// {@endtemplate}
class HummCliCommandRunner extends CompletionCommandRunner<int> {
  /// {@macro humm_command_runner}
  HummCliCommandRunner({
    Logger? logger,
    PubUpdater? pubUpdater,
  })  : _logger = logger ?? Logger(),
        super(executableName, description) {
    // Add root-level options
    argParser.addFlag(
      'verbose',
      help: 'Enables verbose logging, including all executed shell commands.',
      hide: true,
    );

    // Add subcommands
    addCommand(ReleaseCommand(logger: _logger));
    addCommand(ProdChangelogCommand(logger: _logger));
    addCommand(NotifySlackCommand(logger: _logger));
    addCommand(NotifySlackWithErrorCommand(logger: _logger));
    addCommand(InvalidateCloudCommand(logger: _logger));
    addCommand(CheckTranslationsCommand(logger: _logger));
    addCommand(CheckStaticStringsCommands(logger: _logger));
    addCommand(ChangelogCommand(logger: _logger));
    addCommand(JiraSendChangelogWebookCommand(logger: _logger));
  }

  /// Logger instance used for output and logging.
  final Logger _logger;

  @override
  void printUsage() => _logger.info(usage);

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final ArgResults topLevelResults = parse(args);
      if (topLevelResults['verbose'] == true) {
        _logger.level = Level.verbose; // Enable verbose logging.
      }

      // Execute the command and return the appropriate exit code.
      return await runCommand(topLevelResults) ?? ExitCode.success.code;
    } on FormatException catch (e, stackTrace) {
      // Handle format errors (e.g., invalid arguments or commands).
      _logger
        ..err(e.message)
        ..err('$stackTrace') // Log stack trace for debugging.
        ..info('')
        ..info(usage); // Show usage information.
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      // Handle usage errors (e.g., missing required options).
      _logger
        ..err(e.message)
        ..info('')
        ..info(e.usage); // Show command-specific usage information.
      return ExitCode.usage.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    // Handle the `completion` command directly.
    if (topLevelResults.command?.name == 'completion') {
      await super.runCommand(topLevelResults);
      return ExitCode.success.code;
    }

    // Log parsed arguments in verbose mode.
    _logger
      ..detail('Argument information:')
      ..detail('  Top-level options:');
    for (final String option in topLevelResults.options) {
      if (topLevelResults.wasParsed(option)) {
        _logger.detail('  - $option: ${topLevelResults[option]}');
      }
    }

    // Log command-specific options in verbose mode.
    if (topLevelResults.command != null) {
      final ArgResults commandResult = topLevelResults.command!;
      _logger
        ..detail('  Command: ${commandResult.name}')
        ..detail('    Command options:');
      for (final String option in commandResult.options) {
        if (commandResult.wasParsed(option)) {
          _logger.detail('    - $option: ${commandResult[option]}');
        }
      }
    }

    // Run the specified command.
    final int? exitCode = await super.runCommand(topLevelResults);

    return exitCode;
  }
}
