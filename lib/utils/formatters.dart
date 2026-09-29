import 'package:intl/intl.dart';

/// Formatting utilities for dates, phone numbers, and display text.
class Formatters {
  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy • hh:mm a');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  /// Formats a DateTime into a user-friendly timestamp.
  static String formatDateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);

  /// Formats a DateTime into a date string.
  static String formatDate(DateTime dateTime) => _dateFormat.format(dateTime);

  /// Formats phone number for clean display.
  static String formatPhoneNumber(String phone) {
    if (phone.isEmpty) return '';
    final cleaned = phone.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  /// Truncates long text gracefully with ellipsis.
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

/// Alias for backwards-compatibility
typedef AppFormatters = Formatters;
