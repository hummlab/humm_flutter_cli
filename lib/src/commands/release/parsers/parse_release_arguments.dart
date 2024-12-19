import 'package:args/args.dart';
import 'package:humm_cli/src/commands/release/models/release_options.dart';

/// Parses the release-related arguments passed to the command-line interface (CLI).
///
/// This function processes the arguments related to the release, including whether the
/// command is running in a Continuous Integration (CI) environment, the branch name,
/// the version, the tag prefix, and the build number. It returns a [ReleaseOptions] object
/// containing the parsed values.
///
/// [args] is the result of parsing the command-line arguments, typically passed from the CLI.
///
/// Returns a [ReleaseOptions] object containing the parsed release configuration.
///
/// Example usage:
/// ```dart
/// final releaseOptions = await parseReleaseArguments(args);
/// ```
Future<ReleaseOptions> parseReleaseArguments(ArgResults args) async {
  bool ci = false;
  final List<String> prefixes = args.arguments;

  // Check if the '--ci' flag is present, indicating CI environment
  if (prefixes.contains('--ci')) {
    ci = true;
    prefixes.remove('--ci');
  }

  // Retrieve the value of the 'branch' argument, which specifies the branch name
  final String? branch = args['branch'];

  // Retrieve the value of the 'set-version' argument, which specifies the version
  final String? versionArg = args['set-version'];

  // Retrieve the value of the 'tag-prefix' argument, which specifies the tag prefix
  final String? tag = args['tag-prefix'];

  // Retrieve the value of the 'set-bn' argument, which specifies the build number
  final String? buildNumber = args['set-bn'];

  // Determine the prefix for the release, using the tag if available
  String prefix = '';
  if (prefixes.isNotEmpty && tag != null) {
    prefix = '${tag}_';
  }

  // Return the ReleaseOptions object with the parsed values
  return ReleaseOptions(
    prefix: prefix,
    prefixRaw: tag,
    ci: ci,
    version: versionArg,
    branch: branch,
    buildNumber: buildNumber,
  );
}
