import 'dart:io';
import 'package:path/path.dart' as path;

void checkApplicationDirectory() {
  final currentDirectory = Directory.current.path;
  final pubspecPath = path.join(currentDirectory, 'pubspec.yaml');

  if (!File(pubspecPath).existsSync()) {
    throw FileSystemException(
        'Missing pubspec.yaml', 'The file pubspec.yaml was not found in the current directory: $currentDirectory');
  }

  print('The pubspec.yaml file was found in the current directory.');
}
