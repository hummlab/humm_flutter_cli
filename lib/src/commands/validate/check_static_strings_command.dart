import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:humm_cli/src/services/files/files_service.dart';
import 'package:humm_cli/src/core/exceptions/exception_handler.dart';
import 'package:mason_logger/mason_logger.dart';

/// A command that checks for static strings used as labels in widget definitions.
///
/// This command performs the following tasks:
/// - Scans all `.dart` files in the project.
/// - Identifies occurrences of static strings in widget definitions, where static
///   strings are used directly as labels or text without localization.
/// - Ignores certain lines and cases based on predefined exceptions to reduce false positives.
/// - Reports lines where issues are found, providing the file name and line number.
///
/// This command helps maintain localization standards by identifying hardcoded strings
/// that should be replaced with localized versions.
class CheckStaticStringsCommands extends Command<int> {
  /// Creates an instance of [CheckStaticStringsCommands].
  ///
  /// Requires a [Logger] instance for logging output during execution.
  CheckStaticStringsCommands({
    required Logger logger,
  }) : _logger = logger {
    argParser.addFlag(
      'ci',
      help: 'Indicates that the command is running in a CI environment.',
    );
  }

  @override
  String get description => 'Checks if code contains static strings as labels in widgets.';

  @override
  String get name => 'check_strings';

  final Logger _logger;

  @override
  Future<int> run() async {
    try {
      // Get the current working directory.
      final FileService fileService = FileService(_logger);
      final String currentDir = Directory.current.path;

      // Find all `.dart` files in the project directory.
      final List<File> dartFiles = await fileService.findDartFiles(currentDir);

      // Exit early if no `.dart` files are found.
      if (dartFiles.isEmpty) {
        _logger.warn('No Dart files found in the project');
        return ExitCode.success.code;
      }

      final List<String> filesWithIssues = <String>[];

      // Process each Dart file.
      for (final File file in dartFiles) {
        final String content = await file.readAsString();

        // Process files containing widget definitions.
        if (widgetRegex.hasMatch(content)) {
          await _processFile(file, content, filesWithIssues);
        }
      }

      // Summarize results.
      if (filesWithIssues.isEmpty) {
        _logger.success('No static strings found in widgets!');
        return ExitCode.success.code;
      }

      _logger.err('Found static strings in the following lines:');
      for (final String issue in filesWithIssues) {
        _logger.info(issue);
      }
      _logger.err('Total issues found: ${filesWithIssues.length}');
      return ExitCode.software.code;
    } on Exception catch (e) {
      // Handle exceptions using a custom exception handler.
      final ExceptionHandler exceptionHandler = ExceptionHandler(logger: _logger);
      return exceptionHandler.handleException(e);
    }
  }

  /// A list of common exceptions for lines to be ignored.
  /// These include keywords, import statements, comments, and other non-widget related code.
  static const List<String> lineExceptions = <String>[
    'import',
    'case',
    'package',
    '//',
    '/',
    'fontFamily',
    'routeSettings',
    'DateFormat',
    'extends',
    'implements',
    'return',
    '@override',
    'super',
    'throw',
    'typedef',
    'class',
    'const',
    'static',
    'factory',
    'get',
    'set',
    '@visibleForTesting',
    'assert',
    'part',
    'export',
  ];

  // Regular expressions used to identify patterns in code.
  static final RegExp widgetRegex = RegExp(r'class\s+\w+\s+extends\s+(StatelessWidget|StatefulWidget)');
  static final RegExp singleQuoteRegex = RegExp(r"'(.*?)'");
  static final RegExp doubleQuoteRegex = RegExp(r'"(.*?)"');
  static final RegExp interpolationRegex = RegExp(r'\$\{[^}]+\}|\$[a-zA-Z_][a-zA-Z0-9_]*');
  static final RegExp assignmentRegex = RegExp(r'(final|var|String|int|double|bool)\s+\w+\s*=');
  static final RegExp routeRegex = RegExp(r'\/[\w-]+(?:\/[\w-]+)*(?:\?[^\\"]+)?');

  /// Processes a single Dart file, checking for static strings in its content.
  ///
  /// If issues are found, they are added to [filesWithIssues].
  Future<void> _processFile(File file, String content, List<String> filesWithIssues) async {
    final List<String> lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i].trim();

      // Skip empty lines and lines matching exceptions.
      if (line.isEmpty || _checkExceptionForLine(line)) continue;

      // Skip lines containing variable assignments.
      if (assignmentRegex.hasMatch(line)) continue;

      // Identify and report issues in the current line.
      final List<String> issues = _findIssuesInLine(line, file.path, i + 1);
      if (issues.isNotEmpty) {
        filesWithIssues.addAll(issues);
      }
    }
  }

  /// Identifies issues in a specific line and returns them as a list of strings.
  List<String> _findIssuesInLine(String line, String filePath, int lineNumber) {
    final List<String> issues = <String>[];

    void checkQuotes(RegExp regex) {
      for (final RegExpMatch match in regex.allMatches(line)) {
        final String? matchedString = match.group(1);
        if (matchedString != null && _hasIssue(matchedString, line)) {
          issues.add('$filePath:$lineNumber -> $line');
          break;
        }
      }
    }

    // Check for static strings in single and double quotes.
    checkQuotes(singleQuoteRegex);
    if (issues.isEmpty) checkQuotes(doubleQuoteRegex);

    return issues;
  }

  /// Determines if a matched string represents a localization issue.
  bool _hasIssue(String matchedString, String line) {
    if (routeRegex.hasMatch(matchedString)) return false;

    if (interpolationRegex.hasMatch(matchedString)) {
      final String withoutInterpolation = matchedString.replaceAll(interpolationRegex, '').trim();
      if (withoutInterpolation.isEmpty || _isSimpleFormatting(withoutInterpolation)) {
        return false;
      }
    }

    return !line.contains('Intl.message') &&
        !line.contains('// ignore:') &&
        !_isTranslatedString(line) &&
        !_isSimpleValue(matchedString);
  }

  /// Checks if a line matches any of the predefined exceptions.
  bool _checkExceptionForLine(String line) {
    return lineExceptions.any((String exception) => line.startsWith(exception));
  }

  /// Checks if a string consists of simple formatting characters.
  bool _isSimpleFormatting(String text) {
    return RegExp(r'^[-:,./\s]*$').hasMatch(text);
  }

  /// Determines if a line contains a translated string.
  bool _isTranslatedString(String line) {
    final List<String> translationMarkers = <String>[
      'Strings.i.',
      '.translate',
      'Trans(',
      '.getName',
      '.toString',
      '.name',
      'context.l10n',
    ];
    return translationMarkers.any((String marker) => line.contains(marker));
  }

  /// Checks if a string is a simple numeric or formatting value.
  bool _isSimpleValue(String text) {
    return text.isEmpty || RegExp(r'^[0-9.,-]+$').hasMatch(text) || RegExp(r'^[-:,./\s]*$').hasMatch(text);
  }
}
