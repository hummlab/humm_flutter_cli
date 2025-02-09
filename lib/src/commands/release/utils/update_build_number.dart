import 'dart:io';

import 'package:humm_cli/src/core/exceptions/exceptions.dart';

/// Updates the build number in the `pubspec.yaml` file.
///
/// This function reads the current version from the `pubspec.yaml` file,
/// increments or sets a new build number, and updates the file.
///
/// Throws:
/// - [NoPubspecFileFoundException] if the `pubspec.yaml` file is not found.
/// - [WrongBuildVersionFromCommandLineException] if the build number provided is invalid.
/// - [WrongVersionProvidedException] if the version argument is improperly formatted.
///
/// Parameters:
/// - [versionArg]: Optional version argument to override the current version.
/// - [buildNumber]: Optional build number to set explicitly.
///
/// Returns:
/// - A `String` representing the updated version in `pubspec.yaml`.
Future<String> updateBuildNumber(
  String? versionArg,
  String? buildNumber,
) async {
  final File pubspecFile = File('pubspec.yaml');
  if (!(await pubspecFile.exists())) {
    throw NoPubspecFileFoundException();
  }

  // Read the current content of `pubspec.yaml`.
  final List<String> pubspecContent = await pubspecFile.readAsLines();
  final String currentVersion = _getCurrentVersion(pubspecContent);
  final String versionPart = currentVersion.split("+").first;

  // Determine the current or provided build number.
  int? pubBuildNumber = _getBuildNumber(buildNumber, currentVersion);

  // Increment build number if not explicitly provided.
  if (buildNumber == null && pubBuildNumber != null) {
    pubBuildNumber += 1;
  }

  // Create a new version string.
  final String newVersion = _createNewVersion(versionArg, versionPart, pubBuildNumber);

  // Update the `pubspec.yaml` file with the new version.
  _updatePubspecFile(pubspecContent, newVersion, pubspecFile);

  return newVersion;
}

/// Retrieves the build number from the current version or provided argument.
///
/// If no build number is explicitly provided, it attempts to parse the build number
/// from the current version string.
///
/// Throws:
/// - [WrongBuildVersionFromCommandLineException] if the provided build number is invalid.
///
/// Parameters:
/// - [buildNumber]: Optional build number from the command-line arguments.
/// - [currentVersion]: The current version string from `pubspec.yaml`.
///
/// Returns:
/// - An `int` representing the build number, or `null` if not found.
int? _getBuildNumber(String? buildNumber, String currentVersion) {
  late int? number;
  if (buildNumber == null) {
    number = int.tryParse(currentVersion.split("+").last);
    return number;
  } else {
    number = int.tryParse(buildNumber);
    if (number == null) {
      throw WrongBuildVersionFromCommandLineException();
    }
  }
  return number;
}

/// Extracts the current version string from the `pubspec.yaml` content.
///
/// Finds the line starting with `version` and parses the version string.
///
/// Throws:
/// - [FormatException] if the version line is improperly formatted.
///
/// Parameters:
/// - [pubspecContent]: List of lines from `pubspec.yaml`.
///
/// Returns:
/// - A `String` representing the current version.
String _getCurrentVersion(List<String> pubspecContent) {
  final String wantedLine = pubspecContent.firstWhere((String line) => line.startsWith('version'));
  return wantedLine.replaceAll('version:', '').trim();
}

/// Creates a new version string based on the current version or provided arguments.
///
/// This function increments the patch version if no explicit version argument
/// is provided and appends the build number if available.
///
/// Throws:
/// - [WrongVersionProvidedException] if the provided version argument is invalid.
/// - [FormatException] if the current version is improperly formatted.
///
/// Parameters:
/// - [versionArg]: Optional version argument to override the current version.
/// - [currentVersion]: The current version string without the build number.
/// - [buildNumber]: Optional build number to append.
///
/// Returns:
/// - A `String` representing the new version.
String _createNewVersion(
  String? versionArg,
  String currentVersion,
  int? buildNumber,
) {
  int? mainVersion, featuresVersion, fixVersionPart;

  if (versionArg != null) {
    // Parse the provided version argument.
    mainVersion = int.tryParse(versionArg.split('.')[0]);
    featuresVersion = int.tryParse(versionArg.split('.')[1]);
    fixVersionPart = int.tryParse(versionArg.split('.')[2]);
    if (fixVersionPart == null || mainVersion == null || featuresVersion == null) {
      throw WrongVersionProvidedException();
    }
  } else {
    // Increment the patch version from the current version.
    final List<int?> parts = currentVersion.split('.').map(int.tryParse).toList();

    if (parts.any((int? part) => part == null)) {
      throw FormatException();
    }

    mainVersion = parts[0];
    featuresVersion = parts[1];
    fixVersionPart = parts[2]! + 1;
  }

  // Construct the new version string.
  if (buildNumber != null) {
    return '$mainVersion.$featuresVersion.$fixVersionPart+$buildNumber';
  }

  return '$mainVersion.$featuresVersion.$fixVersionPart';
}

/// Updates the `pubspec.yaml` file with the new version string.
///
/// This function replaces the `version` line in the file with the new version.
///
/// Parameters:
/// - [pubspecContent]: List of lines from `pubspec.yaml`.
/// - [newVersion]: The new version string to set.
/// - [pubspecFile]: The `File` object representing `pubspec.yaml`.
void _updatePubspecFile(List<String> pubspecContent, String newVersion, File pubspecFile) {
  final String wantedLine = pubspecContent.firstWhere((String line) => line.startsWith('version'));
  final int wantedLineIndex = pubspecContent.indexOf(wantedLine);

  // Replace the version line.
  pubspecContent.removeAt(wantedLineIndex);
  pubspecContent.insert(wantedLineIndex, 'version: $newVersion');

  // Write the updated content back to the file.
  pubspecFile.writeAsStringSync('${pubspecContent.join('\n')}\n');
}
