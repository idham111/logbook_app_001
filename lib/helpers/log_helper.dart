import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

class LogHelper {
  static final Logger _logger = Logger('LogbookApp');
  static bool _initialized = false;

  static void init({Level level = Level.ALL}) {
    if (_initialized) return;

    Logger.root.level = level;

    Logger.root.onRecord.listen((LogRecord record) {
      final time = DateFormat('HH:mm:ss').format(record.time);
      final lvl = record.level.name.padRight(7);
      final src = record.loggerName;
      final msg = record.message;

      final color = _getColor(record.level);
      final reset = '\x1B[0m';

      // ignore: avoid_print
      print('$color[$time][$lvl][$src] -> $msg$reset');

      if (record.error != null) {
        // ignore: avoid_print
        print('$color  ↳ Error: ${record.error}$reset');
      }
      if (record.stackTrace != null) {
        // ignore: avoid_print
        print('$color  ↳ StackTrace: ${record.stackTrace}$reset');
      }
    });

    _initialized = true;
    _logger.info('LogHelper initialized (level: ${level.name})');
  }

  static void info(String message, {String source = 'Unknown'}) {
    Logger(source).info(message);
  }

  static void warning(String message, {String source = 'Unknown'}) {
    Logger(source).warning(message);
  }

  static void severe(String message,
      {String source = 'Unknown', Object? error, StackTrace? stackTrace}) {
    Logger(source).severe(message, error, stackTrace);
  }

  static void verbose(String message, {String source = 'Unknown'}) {
    Logger(source).fine(message);
  }

  static String _getColor(Level level) {
    if (level >= Level.SEVERE) return '\x1B[31m';
    if (level >= Level.WARNING) return '\x1B[33m';
    if (level >= Level.INFO) return '\x1B[32m';
    return '\x1B[34m';
  }
}
