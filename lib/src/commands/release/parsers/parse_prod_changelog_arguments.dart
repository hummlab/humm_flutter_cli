import 'package:args/args.dart';

/// Parses the arguments for the production changelog command.
///
/// This function extracts the version argument from the command-line arguments.
/// If the version argument is not provided or is empty, it throws a [FormatException].
///
/// [args] is the result of parsing the command-line arguments, typically passed from the CLI.
///
/// Returns the version string as a [String] if the version argument is valid.
///
/// Throws [FormatException] if the version argument is missing or empty.
///
/// Example usage:
/// ```dart
/// final version = await parseProdChangeLogArguments(args);
/// ```
Future<String> parseProdChangeLogArguments(ArgResults args) async {
  // Retrieve the 'version' argument passed in the command line
  final String? versionArg = args['version'];

  // If the version argument is missing or empty, throw a FormatException
  if (versionArg == null || versionArg == '') {
    throw FormatException();
  }

  // Return the version string
  return versionArg;
}
