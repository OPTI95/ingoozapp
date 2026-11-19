import 'package:logger/logger.dart';

/// Thin wrapper around [Logger] so the rest of the app depends on a stable
/// surface instead of the package directly.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 6,
      lineLength: 90,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void d(Object? message) => _logger.d(message);
  static void i(Object? message) => _logger.i(message);
  static void w(Object? message) => _logger.w(message);

  static void e(Object? message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
