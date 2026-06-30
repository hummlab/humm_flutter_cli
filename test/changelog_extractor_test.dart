import 'dart:io';

import 'package:humm_cli/src/services/files/changelog_extractor.dart';
import 'package:test/test.dart';

void main() {
  late Directory previousDirectory;
  late Directory tempDirectory;

  setUp(() {
    previousDirectory = Directory.current;
    tempDirectory = Directory.systemTemp.createTempSync('humm_changelog_test_');
    Directory.current = tempDirectory;
  });

  tearDown(() {
    Directory.current = previousDirectory;
    tempDirectory.deleteSync(recursive: true);
  });

  test('extractCompactForVersion returns header and entries without empty lines', () async {
    File('CHANGELOG.md').writeAsStringSync('''
# 4.0.48 [29.06.2026 16:33]

- [fix] Fixed bottom overlay on Android. [SSO-74]
- [improvement] Added white background on webview open. [SS0-74]
# 4.0.47 [29.06.2026 14:49]

- [feature] Removed buttons on home.
''');

    final List<String> changes = await ChangelogExtractor.extractCompactForVersion('4.0.48');

    expect(
      changes,
      <String>[
        '4.0.48 [29.06.2026 16:33]',
        '- [fix] Fixed bottom overlay on Android. [SSO-74]',
        '- [improvement] Added white background on webview open. [SS0-74]',
      ],
    );
  });

  test('extractEntriesForVersion returns only release note items', () async {
    File('CHANGELOG.md').writeAsStringSync('''
# 4.0.48 [29.06.2026 16:33]

- [fix] Fixed bottom overlay on Android. [SSO-74]
- [improvement] Added white background on webview open. [SS0-74]
''');

    final List<String> changes = await ChangelogExtractor.extractEntriesForVersion('4.0.48');

    expect(
      changes,
      <String>[
        '- [fix] Fixed bottom overlay on Android. [SSO-74]',
        '- [improvement] Added white background on webview open. [SS0-74]',
      ],
    );
  });
}
