import 'dart:io';

/// Pushes local changes and tags to the remote repository.
///
/// This function handles both CI (Continuous Integration) and local environments.
/// In CI mode, the remote URL is adjusted to use SSH format for authentication.
///
/// Throws an error and exits if any Git command fails.
///
/// Parameters:
/// - `tag`: The tag to be pushed to the remote repository.
/// - `ci`: Boolean flag indicating if the operation is being executed in a CI environment.
Future<void> pushChanges({
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
