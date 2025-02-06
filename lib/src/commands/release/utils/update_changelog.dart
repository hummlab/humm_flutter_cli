import 'dart:convert';
import 'dart:io';

import 'package:humm/src/core/exceptions/exceptions.dart';

/// Extension to format `DateTime` into a simple string representation.
extension DateTimeExtension on DateTime {
  /// Converts `DateTime` to a format `dd.MM.yyyy HH:mm`.
  String toSimpleString() {
    final String year = this.year.toString();
    final String month = this.month.toString().padLeft(2, '0');
    final String day = this.day.toString().padLeft(2, '0');
    final String hour = this.hour.toString().padLeft(2, '0');
    final String minute = this.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }
}

/// Tags used to filter changelog-relevant commit messages.
const List<String> _wantedChangelogTags = <String>[
  '[feature]',
  '[fix]',
  '[revert]',
  '[improvement]',
  '[refactor]',
  '[dev-feature]',
  '[dev-fix]',
  '[dev-improvement]',
];

/// Updates the `CHANGELOG.md` file by appending relevant commits.
///
/// The function identifies new commits since the last modification of the
/// changelog, filters them based on predefined tags, and adds them to the
/// changelog with the current version.
///
/// Throws:
/// - [NoChangelogFileFoundException] if the `CHANGELOG.md` file does not exist.
///
/// Parameters:
/// - `version`: The version string to prepend in the changelog.
/// - `prefixRaw`: An optional prefix to filter commit messages further.
Future<void> updateChangelog({
  required String version,
  required String? prefixRaw,
}) async {
  final File changelog = File('CHANGELOG.md');
  if (!(await changelog.exists())) {
    throw NoChangelogFileFoundException();
  }

  // Fetch the last commit that modified the changelog file.
  final ProcessResult lastChangelogCommitResult = Process.runSync(
    'git',
    <String>[
      'rev-list',
      'HEAD',
      '-1',
      'CHANGELOG.md',
    ],
  );

  if (lastChangelogCommitResult.exitCode != 0) {
    stderr.writeln(lastChangelogCommitResult.stderr);
    exit(1);
  }

  final String lastChangelogCommit = (lastChangelogCommitResult.stdout as String).trim();
  // Fetch all commits since the last changelog modification.
  final ProcessResult wantedCommitsResult = Process.runSync(
    'git',
    <String>[
      'rev-list',
      '$lastChangelogCommit...HEAD',
    ],
  );

  if (wantedCommitsResult.exitCode != 0) {
    stderr.writeln(wantedCommitsResult.stderr);
    exit(1);
  }

  List<String> wantedCommits = (wantedCommitsResult.stdout as String).split('\n');
  wantedCommits = wantedCommits.where((String text) => text.isNotEmpty).toList();
  wantedCommits = wantedCommits.map((String text) => text.trim()).toList();

  final List<String> changes = <String>[];

  // Iterate through commits to extract relevant changes.
  for (String commit in wantedCommits) {
    final ProcessResult commitResult = Process.runSync(
      'git',
      <String>[
        'log',
        '--format=%B',
        '-n',
        '1',
        commit,
      ],
      stdoutEncoding: const Utf8Codec(),
    );

    if (commitResult.exitCode != 0) {
      stderr.writeln(commitResult.stderr);
      exit(1);
    }

    final String commitMessage = (commitResult.stdout as String).trim();
    final List<String> commitLines = commitMessage.split('\n');
    // Filter commit messages by tags and optional prefix.
    for (final String line in commitLines) {
      final String trimmedLine = line.trim();
      for (String wantedTag in _wantedChangelogTags) {
        if (prefixRaw != null && prefixRaw.isNotEmpty && trimmedLine.startsWith('[$prefixRaw]')) {
          final String withoutPrefix = trimmedLine.substring('[$prefixRaw]'.length).trim();
          if (withoutPrefix.startsWith(wantedTag)) {
            changes.add(trimmedLine);
            break;
          }
        } else {
          if (trimmedLine.startsWith(wantedTag)) {
            if (prefixRaw != null && trimmedLine.contains(prefixRaw)) {
              changes.add(trimmedLine);
              break;
            }
            if (prefixRaw == null) {
              changes.add(trimmedLine);
              break;
            }
          }
        }
      }
    }
  }

  changes.sort();

  // Add a default change if no relevant commits were found.
  if (changes.isEmpty) {
    changes.add('[dev-improvement] Developer changes.');
  }

  // Format changes as list items.
  for (int i = 0; i < changes.length; i++) {
    if (!changes[i].startsWith('- ')) {
      changes[i] = '- ${changes[i]}';
    }
  }

  final List<String> changelogContent = changelog.readAsLinesSync();

  // Add version header and changes to the beginning of the changelog.
  changelogContent.insert(0, '# $version [${DateTime.now().toSimpleString()}]\n');
  changelogContent.insertAll(1, changes);

  // Write updated content back to the changelog file.
  changelog.writeAsStringSync('${changelogContent.join('\n')}\n');
}
