import 'package:args/args.dart';
import 'package:humm_cli/src/args/args_keys/common_args.dart';

// Adds shared flags 
class CommonFlagsHandler {
  static List<Function(ArgParser argParser)> commonArgs = <Function(ArgParser argParser)>[
    _addCiFlag,
  ];

  static void addCommonFlags(ArgParser argParser) {
    for (final Function(ArgParser argParser) callback in commonArgs) {
      callback.call(argParser);
    }
  }

  static void _addCiFlag(ArgParser argParser) {
    argParser.addFlag(
      CommonArgs.noCi,
      help: 'Indicates that the command is running in a CI environment.',
      negatable: false,
    );
  }
}
