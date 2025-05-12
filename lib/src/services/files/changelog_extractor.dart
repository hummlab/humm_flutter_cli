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
}