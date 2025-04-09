import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// A command that finds and removes unused ARB keys from localization files.
///
/// This command performs the following tasks:
/// - Scans all `.arb` files in the specified directory
/// - Identifies all ARB keys
/// - Checks which keys are used in the source code
/// - Identifies unused keys and offers to remove them
///
/// This command helps maintain clean localization files by removing unused translations.
class CleanupArbCommand extends Command<int> {
  /// Creates an instance of [CleanupArbCommand].
  ///
  /// Requires a [Logger] instance for logging output during execution.
  CleanupArbCommand({
    required Logger logger,
  }) : _logger = logger {
    // Add specific arguments for this command
    argParser
      ..addOption(
        'arb-dir',
        abbr: 'a',
        help: 'Path to the directory containing ARB files',
        defaultsTo: 'lib/l10n',
      )
      ..addOption(
        'source-dir',
        abbr: 's',
        help: 'Path to the source code directory to search',
        defaultsTo: 'lib',
      )
      ..addOption(
        'access-pattern',
        abbr: 'p',
        help: 'Translation access pattern (e.g., S.current, S.of(context), AppLocalizations.of(context))',
        defaultsTo: 'S.current',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose output',
        defaultsTo: false,
      )
      ..addFlag(
        'dry-run',
        abbr: 'd',
        help: 'Show what would be done without making changes',
        defaultsTo: false,
      );
  }

  @override
  String get description => 'Finds and removes unused ARB keys from localization files';

  @override
  String get name => 'cleanup_arb';

  final Logger _logger;

  @override
  Future<int> run() async {
    try {
      final ArgResults args = argResults!;
      
      // Parse command options
      final String arbDirectory = args['arb-dir'] as String;
      final String sourceDirectory = args['source-dir'] as String;
      final String accessPattern = args['access-pattern'] as String;
      final bool isVerbose = args['verbose'] as bool;
      final bool isDryRun = args['dry-run'] as bool;

      // Validate directories
      if (!await _validateDirectories(arbDirectory, sourceDirectory)) {
        return ExitCode.usage.code;
      }

      // Step 1: Load all ARB keys
      _logger.info('Loading ARB keys from directory: $arbDirectory');
      final Map<String, bool> allArbKeys = await _loadArbKeys(arbDirectory);
      
      if (allArbKeys.isEmpty) {
        _logger.warn('No ARB keys found in the provided directory');
        return ExitCode.success.code;
      }
      
      _logger.info('Found ${allArbKeys.length} unique ARB keys');

      // Step 2: Search source code for key usage
      _logger.info('Searching for key usage in source code: $sourceDirectory');
      await _findKeyUsage(sourceDirectory, allArbKeys, accessPattern, isVerbose);

      // Step 3: Identify unused keys
      final List<String> unusedKeys = allArbKeys.entries
          .where((MapEntry<String, bool> entry) => !entry.value)
          .map((MapEntry<String, bool> entry) => entry.key)
          .toList();

      // Output results
      if (unusedKeys.isEmpty) {
        _logger.success('All ARB keys are used in the code!');
        return ExitCode.success.code;
      }

      _logger.info('Found ${unusedKeys.length} unused ARB keys:');
      for (int i = 0; i < unusedKeys.length; i++) {
        _logger.info('  ${i + 1}. ${unusedKeys[i]}');
      }

      // Ask for confirmation if not in dry-run mode
      if (!isDryRun) {
        final bool confirmation = _logger.confirm(
          'Do you want to remove these unused keys from ARB files?',
          defaultValue: false,
        );

        if (confirmation) {
          final int removedCount = await _removeUnusedKeys(arbDirectory, unusedKeys);
          _logger.success('Removed $removedCount occurrences of unused keys from ARB files');
        } else {
          _logger.info('No changes were made');
        }
      } else {
        _logger.info('Dry run: No changes were made');
      }

      return ExitCode.success.code;
    } on Exception catch (e) {
      _logger.err('Error: $e');
      return ExitCode.software.code;
    }
  }

  /// Validates that the specified directories exist.
  Future<bool> _validateDirectories(String arbDirectory, String sourceDirectory) async {
    final Directory arbDir = Directory(arbDirectory);
    final Directory sourceDir = Directory(sourceDirectory);

    if (!await arbDir.exists()) {
      _logger.err('ARB directory does not exist: $arbDirectory');
      return false;
    }

    if (!await sourceDir.exists()) {
      _logger.err('Source directory does not exist: $sourceDirectory');
      return false;
    }

    return true;
  }

  /// Loads all keys from ARB files in the specified directory.
  Future<Map<String, bool>> _loadArbKeys(String arbDirectory) async {
    final Map<String, bool> allKeys = <String, bool>{};
    final Directory arbDir = Directory(arbDirectory);
    
    final List<FileSystemEntity> arbFiles = await arbDir
        .list()
        .where((FileSystemEntity entity) => entity is File && entity.path.endsWith('.arb'))
        .toList();

    for (final FileSystemEntity entity in arbFiles) {
      final File arbFile = entity as File;
      final String content = await arbFile.readAsString();
      
      try {
        final Map<String, dynamic> arbMap = jsonDecode(content);
        
        // Extract keys from ARB file (ignoring metadata)
        for (final String key in arbMap.keys) {
          // Skip metadata keys (starting with '@')
          if (!key.startsWith('@')) {
            allKeys[key] = false; // Initially mark all keys as unused
          }
        }
      } catch (e) {
        _logger.err('Error parsing ARB file ${arbFile.path}: $e');
      }
    }
    
    return allKeys;
  }

  /// Searches source code directory for usage of ARB keys.
  Future<void> _findKeyUsage(
    String sourceDirectory,
    Map<String, bool> allArbKeys,
    String accessPattern,
    bool isVerbose,
  ) async {
    final Directory sourceDir = Directory(sourceDirectory);
    
    // List of keys that still need to be found
    List<String> remainingKeys = allArbKeys.keys.toList();
    
    if (isVerbose) {
      _logger.info('Using access pattern: $accessPattern');
    }
    
    // Create RegExp for key extraction based on access pattern
    // Escape any regex special characters in the access pattern
    final String escapedPattern = RegExp.escape(accessPattern);
    final RegExp keyExtractor = RegExp('$escapedPattern\\.([a-zA-Z0-9_]+)\\b');
    
    // Walk through all Dart files in source directory
    await for (final FileSystemEntity entity in sourceDir.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      
      // If all keys have been found, we can stop searching
      if (remainingKeys.isEmpty) {
        if (isVerbose) {
          _logger.info('All keys have been found! Stopping search.');
        }
        break;
      }
      
      // Read file content
      String content;
      try {
        content = await entity.readAsString();
      } catch (e) {
        if (isVerbose) {
          _logger.warn('Could not read file ${entity.path}: $e');
        }
        continue;
      }
      
      // Check if file contains the access pattern
      if (!content.contains(accessPattern)) {
        continue;
      }
      
      // Extract all potential keys from the file
      final Iterable<Match> matches = keyExtractor.allMatches(content);
      
      // Process found keys
      for (final Match match in matches) {
        final String extractedKey = match.group(1)!;
        
        // Check if key is in our list
        if (allArbKeys.containsKey(extractedKey)) {
          allArbKeys[extractedKey] = true; // Mark key as used
          remainingKeys.remove(extractedKey); // Remove from remaining keys
          
          if (isVerbose) {
            _logger.info('Found key "$extractedKey" in ${entity.path}');
          }
        }
      }
    }
  }

  /// Removes unused keys from ARB files.
  Future<int> _removeUnusedKeys(String arbDirectory, List<String> unusedKeys) async {
    final Directory arbDir = Directory(arbDirectory);
    int totalRemoved = 0;
    
    final List<FileSystemEntity> arbFiles = await arbDir
        .list()
        .where((FileSystemEntity entity) => entity is File && entity.path.endsWith('.arb'))
        .toList();
    
    for (final FileSystemEntity entity in arbFiles) {
      final File arbFile = entity as File;
      _logger.info('Processing file: ${arbFile.path}');
      
      String content = await arbFile.readAsString();
      Map<String, dynamic> arbMap;
      
      try {
        arbMap = jsonDecode(content);
      } catch (e) {
        _logger.err('Error parsing ARB file ${arbFile.path}: $e');
        continue;
      }
      
      int removedInThisFile = 0;
      bool fileModified = false;
      
      // Remove unused keys and their metadata
      for (final String key in unusedKeys) {
        bool keyRemoved = false;
        
        // Remove main key
        if (arbMap.containsKey(key)) {
          arbMap.remove(key);
          keyRemoved = true;
        }
        
        // Remove metadata key (@key)
        final String metadataKey = '@$key';
        if (arbMap.containsKey(metadataKey)) {
          arbMap.remove(metadataKey);
          keyRemoved = true;
        }
        
        if (keyRemoved) {
          removedInThisFile++;
          fileModified = true;
        }
      }
      
      // Save modified file
      if (fileModified) {
        // Save with proper formatting
        final JsonEncoder encoder = JsonEncoder.withIndent('  ');
        final String formattedJson = encoder.convert(arbMap);
        await arbFile.writeAsString(formattedJson);
        
        _logger.info('Removed $removedInThisFile keys from ${arbFile.path}');
        totalRemoved += removedInThisFile;
      } else {
        _logger.info('No changes made to ${arbFile.path}');
      }
    }
    
    return totalRemoved;
  }
}