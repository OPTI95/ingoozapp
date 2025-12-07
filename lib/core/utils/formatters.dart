import 'package:intl/intl.dart';

/// Collection of helper methods for formatting waybill-specific fields.
class Formatters {
  Formatters._();

  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static String date(DateTime value) => _dateFormat.format(value);

  static String time(DateTime value) => _timeFormat.format(value);

  static String mileage(int meters) => '${(meters / 1000).toStringAsFixed(1)} км';
}
