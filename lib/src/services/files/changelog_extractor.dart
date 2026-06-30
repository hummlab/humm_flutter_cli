import 'dart:io';

import 'package:humm_cli/src/core/exceptions/exceptions.dart';

abstract class ChangelogExtractor {
  /// Extracts the changelog for a specific version
  /// Returns a list of lines containing the changelog
  static Future<List<String>> extractForVersion(String version) async {
    final File changelog = File('CHANGELOG.md');

    if (!changelog.existsSync()) {
      throw NoChangelogFileFoundException();
    }

    final List<String> changelogContent = changelog.readAsLinesSync();
    final List<String> versionChanges = <String>[];
    bool isVersionFound = false;
    bool isCollecting = false;

    for (final String line in changelogContent) {
      if (line.contains('# $version')) {
        isVersionFound = true;
        isCollecting = true;
        versionChanges.add(line);
        continue;
      }

      if (isCollecting && line.startsWith('# ')) {
        break;
      }

      if (isCollecting) {
        versionChanges.add(line);
      }
    }

    if (!isVersionFound) {
      throw WrongVersionProvidedException();
    }

    return versionChanges;
  }

  /// Extracts a compact changelog for comments and release notes.
  static Future<List<String>> extractCompactForVersion(String version) async {
    final List<String> versionChanges = await extractForVersion(version);

    return versionChanges.where((String line) {
      final String trimmedLine = line.trim();
      return trimmedLine.isNotEmpty;
    }).map((String line) {
      final String trimmedLine = line.trim();
      if (trimmedLine.startsWith('# ')) {
        return trimmedLine.substring(2);
      }

      return trimmedLine;
    }).toList();
  }

  /// Extracts only release note entries for a specific version.
  static Future<List<String>> extractEntriesForVersion(String version) async {
    final List<String> versionChanges = await extractCompactForVersion(version);

    return versionChanges.where((String line) => !line.startsWith(RegExp(r'\d+\.\d+\.\d+'))).toList();
  }
}
