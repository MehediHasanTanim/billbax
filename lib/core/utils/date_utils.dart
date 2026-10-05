import 'package:intl/intl.dart';

/// Date helpers for Asia/Dhaka billing context.
abstract final class AppDateUtils {
  static String formatShort(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Days until [dueDay] this month (or next month if already passed).
  static int daysUntilDueDay(int dueDay, {DateTime? from}) {
    final now = from ?? DateTime.now();
    var due = DateTime(now.year, now.month, dueDay);
    if (due.isBefore(DateTime(now.year, now.month, now.day))) {
      due = DateTime(now.year, now.month + 1, dueDay);
    }
    return due.difference(DateTime(now.year, now.month, now.day)).inDays;
  }
}
