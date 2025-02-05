import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:humm/src/core/exceptions/exception_handler.dart';
import 'package:humm/src/core/environment/environment_config.dart';
import 'package:humm/src/core/exceptions/exceptions.dart';
import 'package:mason_logger/mason_logger.dart';

class InvalidateCloudCommand extends Command<int> {
  InvalidateCloudCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addFlag(
        'ci',
        help: 'Ci helper',
      );
  }

  @override
  String get description => 'Invalidates the CloudFront cache';

  @override
  String get name => 'invalidate';

  final Logger _logger;

  @override
  Future<int> run() async {
    try {
      final String? distributionId = EnvironmentConfig.getCloudDistribution();
      if (distributionId == null) {
        throw AwsDistributionNotFoundException(
          'CloudFront distribution ID not found. Required: CLOUD_DISTRIBUTION',
        );
      }

      _logger.info('Invalidating CloudFront cache...');

      final ProcessResult invalidateResult = Process.runSync(
        'aws',
        <String>[
          'cloudfront',
          'create-invalidation',
          '--distribution-id',
          distributionId,
          '--paths',
          '/*',
        ],
        runInShell: true,
      );

      if (invalidateResult.exitCode != 0) {
        _logger.err('Error during CloudFront invalidation...');
        _logger.err(invalidateResult.stdout);
        _logger.err(invalidateResult.stderr);
        throw Exception('Error during CloudFront invalidation');
      }

      _logger.success('Cache successfully invalidated');
      return ExitCode.success.code;
    } on Exception catch (e) {
      final ExceptionHandler exceptionHandler = ExceptionHandler(logger: _logger);
      return exceptionHandler.handleException(e);
    }
  }
}
