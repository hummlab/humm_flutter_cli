import 'dart:io';

abstract class GitService {
  /// Creates a Git tag with the specified name.
  ///
  /// If the tag creation fails, it throws an [Exception] with the error details.
  static Future<void> createTag({
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

  /// Pushes local changes and tags to the remote repository.
  ///
  /// This function handles both CI (Continuous Integration) and local environments.
  /// In CI mode, the remote URL is adjusted to use SSH format for authentication.
  ///
  /// Throws an error and exits if any Git command fails.
  static Future<void> pushChanges({
    required String tag,
    required bool ci,
  }) async {
    try {
      // Get the remote URL for the repository
      final ProcessResult result = await Process.run(
        'git',
        <String>['config', '--local', 'remote.origin.url'],
      );

      if (result.exitCode != 0) {
        throw Exception('Failed to get remote URL: ${result.stderr}');
      }

      String remoteUrl = result.stdout.toString().trim();
      print('Original remote URL: $remoteUrl');

      // Transform the URL to SSH format if running in CI
      if (remoteUrl.contains('https://github.com/')) {
        remoteUrl = remoteUrl.replaceFirst('https://github.com/', 'git@github.com:');
      } else if (remoteUrl.contains('https://humm@github.com/')) {
        remoteUrl = remoteUrl.replaceFirst('https://humm@github.com/', 'git@github.com:');
      }

      // Handle CI-specific operations
      if (ci) {
        // Add the SSH remote
        final ProcessResult addRemoteResult = Process.runSync(
          'git',
          <String>['remote', 'add', 'originSSH', remoteUrl],
        );

        if (addRemoteResult.exitCode != 0) {
          stderr.write(addRemoteResult.stderr);
          exit(1);
        }

        // Push the current HEAD branch to the SSH remote
        final ProcessResult pushResult = Process.runSync(
          'git',
          <String>['push', '--set-upstream', 'originSSH', 'HEAD'],
        );

        if (pushResult.exitCode != 0) {
          stderr.write(pushResult.stderr);
          exit(1);
        }

        // Push the specified tag to the SSH remote
        final ProcessResult pushTagResult = Process.runSync(
          'git',
          <String>['push', '--set-upstream', 'originSSH', tag],
        );

        if (pushTagResult.exitCode != 0) {
          stderr.write(pushTagResult.stderr);
          exit(1);
        }

        return;
      }

      // Push the current HEAD branch to the default remote
      final ProcessResult pushResult = Process.runSync(
        'git',
        <String>['push', '--set-upstream', 'origin', 'HEAD'],
      );

      if (pushResult.exitCode != 0) {
        stderr.write(pushResult.stderr);
        exit(1);
      }

      // Push the specified tag to the default remote
      final ProcessResult pushTagResult = Process.runSync(
        'git',
        <String>['push', '--set-upstream', 'origin', tag],
      );

      if (pushTagResult.exitCode != 0) {
        stderr.write(pushTagResult.stderr);
        exit(1);
      }
    } catch (e) {
      stderr.writeln('Error occurred while pushing changes: $e');
      exit(1);
    }
  }

  /// Commits changes to the Git repository with the specified commit message.
  ///
  /// The commit will include all changes to tracked files (using `git commit -a`).
  /// If the commit fails, it writes the error to the standard output and exits the program with a non-zero status.
  static Future<void> commitChanges({
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

  /// Switches to the specified Git branch.
  ///
  /// This function first checks if the specified branch exists in the repository.
  /// If the branch exists, it switches to it using `git checkout`. If the branch
  /// does not exist, an error message is printed and the program exits with a non-zero status.
  static Future<void> checkoutToBranch(String branch) async {
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
    bool isLocal = branches.contains(branch);

    String remoteBranch = 'remotes/origin/$branch';
    bool isRemote = branches.contains(remoteBranch);

    if (!isLocal && isRemote) {
      stdout.writeln('Branch $branch is remote. Fetching...');

      final ProcessResult trackBranchResult = await Process.run(
        'git',
        <String>['checkout', '-b', branch, '--track', remoteBranch],
      );

      if (trackBranchResult.exitCode != 0) {
        stdout.writeln('Error during checkouting to $branch: ${trackBranchResult.stderr}');
        exit(1);
      } else {
        stdout.writeln('Checkouted to branch $branch.');
        return;
      }
    }

    if (!isLocal && !isRemote) {
      stdout.writeln('Branch $branch do not exist.');
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
}
