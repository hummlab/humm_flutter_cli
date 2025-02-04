import 'dart:convert';
import 'dart:io';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;

class FileService {
  final Logger logger;

  FileService(this.logger);

  Future<List<File>> findArbFiles(String startDir) async {
    final Directory dir = Directory(startDir);
    final List<File> arbFiles = <File>[];

    logger.info('Searching for arb files...');
    if (await dir.exists()) {
      await for (final FileSystemEntity entity in dir.list(recursive: true)) {
        if (entity is File && path.extension(entity.path) == '.arb') {
          arbFiles.add(entity);
        }
      }
    }

    if (arbFiles.isEmpty) {
      logger.err('No .arb files found in the project.');
    } else {
      logger.info('Found ${arbFiles.length} arb files');
    }

    return arbFiles;
  }

  Future<Map<String, dynamic>> loadArbFile(String filePath) async {
    final File file = File(filePath);
    final String content = await file.readAsString();
    final Map<String, dynamic> json = jsonDecode(content);
    return json;
  }

  Future<List<File>> findDartFiles(
    String startDir,
  ) async {
    final Directory dir = Directory(startDir);
    final List<File> dartFiles = <File>[];

    if (!await dir.exists()) {
      logger.warn('Directory $startDir does not exist');
      return dartFiles;
    }

    await for (final FileSystemEntity entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity);
      }
    }
    return dartFiles;
  }
}
