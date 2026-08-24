import 'package:intl/intl.dart';

/// Formatter for dates and timestamps in KiranaOS.
abstract final class DateFormatter {
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _billSeqDateFormat = DateFormat('yyyyMMdd');

  static String formatDateTime(DateTime dateTime) =>
      _dateTimeFormat.format(dateTime.toLocal());

  static String formatDate(DateTime dateTime) =>
      _dateFormat.format(dateTime.toLocal());

  static String formatTime(DateTime dateTime) =>
      _timeFormat.format(dateTime.toLocal());

  static String formatForBillNumber(DateTime dateTime) =>
      _billSeqDateFormat.format(dateTime.toLocal());
}
