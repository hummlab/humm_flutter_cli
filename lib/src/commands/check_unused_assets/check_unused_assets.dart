import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';
import 'package:mason_logger/mason_logger.dart';

/// A command that checks for unused assets in the project.
class CheckUnusedAssetsCommand extends Command<int> {
  CheckUnusedAssetsCommand({required Logger logger}) : _logger = logger;

  @override
  String get description => 'Checks if there are unused assets in the project.';

  @override
  String get name => 'check_unused_assets';

  final Logger _logger;

  @override
  Future<int> run() async {
    try {
      final List<String> assetFiles = _getAllAssetsFromFolder();
      if (assetFiles.isEmpty) {
        _logger.warn('No assets found in the assets/ directory.');
        return ExitCode.success.code;
      }

      final List<String> pubspecAssets = _getAssetsFromPubspec();
      if (pubspecAssets.isEmpty) {
        _logger.warn('No assets declared in pubspec.yaml. Are they missing?');
        return ExitCode.success.code;
      }

      final List<File> dartFiles = await _findDartFiles();
      final Set<String> usedAssets = await _findUsedAssets(dartFiles, assetFiles);

      final List<String> unusedAssets = assetFiles.where((String asset) => !usedAssets.contains(asset)).toList();

      if (unusedAssets.isEmpty) {
        _logger.success('All assets are used in the project!');
        return ExitCode.success.code;
      }

      _logger.err('Found unused assets:');
      for (final String asset in unusedAssets) {
        _logger.info(asset);
      }
      _logger.err('Total unused assets: ${unusedAssets.length}');
      return ExitCode.software.code;
    } catch (e) {
      _logger.err('Error while checking unused assets: $e');
      return ExitCode.software.code;
    }
  }

  List<String> _getAllAssetsFromFolder() {
    final Directory assetsDir = Directory('assets');
    if (!assetsDir.existsSync()) return <String>[];

    return assetsDir
        .listSync(recursive: true)
        .whereType<File>()
        .map((File file) => file.path.replaceAll('\\', '/'))
        .toList();
  }

  List<String> _getAssetsFromPubspec() {
    final File pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) {
      _logger.err('pubspec.yaml not found!');
      return <String>[];
    }

    final String yamlContent = pubspec.readAsStringSync();
    final YamlMap yamlMap = loadYaml(yamlContent);
    final YamlMap? flutterSection = yamlMap['flutter'];
    if (flutterSection == null || !flutterSection.containsKey('assets')) return <String>[];

    final List<dynamic> rawAssets = flutterSection['assets'] as List<dynamic>;
    return rawAssets.map((dynamic asset) => asset.toString()).toList();
  }

  Future<List<File>> _findDartFiles() async {
    final Directory currentDir = Directory.current;
    final List<File> dartFiles = <File>[];

    await for (FileSystemEntity entity in currentDir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity);
      }
    }

    return dartFiles;
  }

  Future<Set<String>> _findUsedAssets(List<File> dartFiles, List<String> assetFiles) async {
    final Set<String> usedAssets = <String>{};

    for (final File file in dartFiles) {
      final String content = await file.readAsString();
      for (final String asset in assetFiles) {
        if (content.contains(asset)) {
          usedAssets.add(asset);
        }
      }
    }

    return usedAssets;
  }
}
