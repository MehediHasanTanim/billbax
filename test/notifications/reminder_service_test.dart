import 'package:flutter_test/flutter_test.dart';

import 'package:bilbax/features/notifications/services/reminder_service.dart';

void main() {
  group('computeNextReminderAt', () {
    test('schedules 2 days before due day this month when still in future', () {
      // From Oct 1, due day 15 → reminder Oct 13 09:00
      final from = DateTime(2026, 10, 1, 8);
      final next = computeNextReminderAt(15, from: from);
      expect(next, DateTime(2026, 10, 13, 9));
    });

    test('rolls to next month when reminder already passed', () {
      // From Oct 14, due day 15 → reminder was Oct 13 → next is Nov 13
      final from = DateTime(2026, 10, 14, 10);
      final next = computeNextReminderAt(15, from: from);
      expect(next, DateTime(2026, 11, 13, 9));
    });

    test('notificationIdForBill is non-negative', () {
      expect(notificationIdForBill('abc'), greaterThanOrEqualTo(0));
      expect(notificationIdForBill('xyz-uuid'), lessThan(1 << 31));
    });
  });
}
