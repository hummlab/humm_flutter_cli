import 'package:args/command_runner.dart';
import 'package:humm/src/commands/release/models/release_options.dart';
import 'package:humm/src/core/exception_handler.dart';
import 'package:humm/src/git_commands/_git.dart';
import 'package:humm/src/git_commands/tags/create_tag.dart';
import 'package:humm/src/commands/release/parsers/parse_release_arguments.dart';
import 'package:humm/src/commands/release/utils/update_build_number.dart';
import 'package:humm/src/commands/release/utils/update_changelog.dart';
import 'package:mason_logger/mason_logger.dart';

/// A command that automates the release process of an application.
///
/// This command handles:
/// - Switching to the specified branch or a default branch (e.g., `develop`).
/// - Updating the build number and optionally setting a specific version.
/// - Updating the changelog with the latest changes.
/// - Committing pre-release updates.
/// - Creating a Git tag for the release.
/// - Pushing changes and the release tag to a remote repository.
///
/// The command supports additional options for CI environments and customizations
/// such as setting a tag prefix, specific version, or build number.
class ReleaseCommand extends Command<int> {
  /// Creates a new instance of [ReleaseCommand].
  ///
  /// Takes a [Logger] instance for logging output during the execution of the command.
  ReleaseCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser.addFlag(
      'ci',
      help: 'Indicates that the command is running in a CI environment.',
    );
    argParser.addOption(
      'branch',
      help: 'Specifies the branch to switch to before releasing.',
    );
    argParser.addOption(
      'set-version',
      help: 'Sets a specific version for the release.',
    );
    argParser.addOption(
      'set-bn',
      help: 'Sets a specific build number for the release.',
    );
    argParser.addOption(
      'tag-prefix',
      help: 'Sets a prefix for the release tag.',
    );
  }

  @override
  String get description => 'Automates the release process of the application.';

  @override
  String get name => 'release';

  final Logger _logger;

  @override
  Future<int> run() async {
    try {
      /// Parses the arguments provided to the command and validates them.
      final ReleaseOptions releaseOptions = await parseReleaseArguments(argResults!);

      _logger.info('Checking out to branch ${(releaseOptions.branch ?? 'develop')}');
      await checkoutToBranch(releaseOptions.branch ?? 'develop');
      _logger.success('Switched to branch ${(releaseOptions.branch ?? 'develop')}');

      _logger.info('Updating build number...');
      final String version = await updateBuildNumber(
        releaseOptions.version,
        releaseOptions.buildNumber,
      );
      _logger.success('Updated build number to $version');

      _logger.info('Updating changelog...');
      await updateChangelog(
        version: version,
        prefixRaw: releaseOptions.prefixRaw,
      );
      _logger.success('Updated changelog');

      _logger.info('Committing pre-release updates...');
      await commitChanges();
      _logger.success('Changes committed');

      final String tagVersion = version.split('+').first;
      final String tag = '${releaseOptions.prefix}$tagVersion';

      _logger.info('Creating tag...');
      createTag(tag: tag);
      _logger.success('Tag $tag created');

      _logger.info('Pushing changes...');
      await pushChanges(
        tag: tag,
        ci: releaseOptions.ci,
      );
      _logger.success('Changes pushed');

      _logger.success('Exiting...');
      return ExitCode.success.code;
    } on Exception catch (e) {
      /// Handles any exceptions that occur during the execution of the command.
      final exceptionHandler = ExceptionHandler(logger: _logger);
      return exceptionHandler.handleException(e);
    }
  }
}
