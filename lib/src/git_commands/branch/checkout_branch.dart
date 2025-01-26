import 'dart:io';

/// Switches to the specified Git branch.
///
/// This function first checks if the specified branch exists in the repository.
/// If the branch exists, it switches to it using `git checkout`. If the branch
/// does not exist, an error message is printed and the program exits with a non-zero status.
///
/// Example usage:
/// ```dart
/// await checkoutToBranch('feature/new-feature');
/// ```
Future<void> checkoutToBranch(String branch) async {
  // Get the list of all branches (local and remote)
  final ProcessResult branchListResult = await Process.run(
    'git',
    <String>['branch', '-a'],
  );

  // If the branch list command fails, print the error and exit
  if (branchListResult.exitCode != 0) {
    stdout.writeln(branchListResult.stderr);
    exit(1);
  }

  // Extract the branch names from the command output
  final List<String> branches = (branchListResult.stdout as String)
      .split('\n')
      .map((String branch) => branch.replaceAll('*', '').trim())
      .toList();

  // Check if the specified branch exists
  if (!branches.contains(branch)) {
    stdout.writeln('Branch $branch does not exist.');
    exit(1);
  }

  // Get the name of the current branch
  final ProcessResult branchResult = await Process.run(
    'git',
    <String>['branch', '--show-current'],
  );

  // If the branch check command fails, print the error and exit
  if (branchResult.exitCode != 0) {
    stdout.writeln(branchResult.stderr);
    exit(1);
  }

  final String currentBranch = (branchResult.stdout as String).trim();

  // Switch to the specified branch if not already on it
  if (currentBranch != branch) {
    final ProcessResult switchResult = await Process.run(
      'git',
      <String>['checkout', branch],
    );

    // If switching branches fails, print the error and exit
    if (switchResult.exitCode != 0) {
      stdout.writeln(switchResult.stderr);
      exit(1);
    } else {
      stdout.writeln('Switched to $branch branch.');
    }
  } else {
    stdout.writeln('Already on $branch branch.');
  }
}
