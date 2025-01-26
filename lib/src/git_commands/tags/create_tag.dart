import 'dart:io';

/// Creates a Git tag with the specified name.
///
/// If the tag creation fails, it throws an [Exception] with the error details.
///
/// Example usage:
/// ```dart
/// await createTag(tag: 'v1.0.0');
/// ```
Future<void> createTag({
  required String tag,
  bool signed = false,
}) async {
  // Build the Git command arguments
  final List<String> arguments = signed ? <String>['tag', '-s', tag] : <String>['tag', tag];

  final ProcessResult result = Process.runSync(
    'git',
    arguments,
  );

  if (result.exitCode != 0) {
    final String errorMessage = result.stderr as String;
    throw Exception('Failed to create tag "$tag". Git error: $errorMessage');
  }

  stdout.writeln('Tag "$tag" created successfully.');
}
