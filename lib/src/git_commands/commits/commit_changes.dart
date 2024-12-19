import 'dart:io';

/// Commits changes to the Git repository with the specified commit message.
///
/// The commit will include all changes to tracked files (using `git commit -a`).
/// If the commit fails, it writes the error to the standard output and exits the program with a non-zero status.
///
/// Example usage:
/// ```dart
/// await commitChanges(commitMsg: 'Fix bug in payment module');
/// ```
Future<void> commitChanges({
  String commitMsg = 'Pre-release updates',
}) async {
  // Run the git commit command with the specified commit message
  final ProcessResult result = await Process.run(
    'git',
    <String>[
      'commit',
      '-a',
      '-m',
      commitMsg,
    ],
  );

  // If the commit command fails, print the error and exit
  if (result.exitCode != 0) {
    stdout.writeln(result.stderr);
    exit(1);
  }
}
