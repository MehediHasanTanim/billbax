import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../bills/data/models/bill_account.dart';

/// Computes the next reminder instant: 2 days before [dayOfMonth] at 09:00 local.
@visibleForTesting
DateTime computeNextReminderAt(
  int dayOfMonth, {
  DateTime? from,
  int daysBefore = 2,
  int hour = 9,
  int minute = 0,
}) {
  final now = from ?? DateTime.now();
  var reminder = DateTime(now.year, now.month, dayOfMonth, hour, minute)
      .subtract(Duration(days: daysBefore));

  if (!reminder.isAfter(now)) {
    reminder = DateTime(now.year, now.month + 1, dayOfMonth, hour, minute)
        .subtract(Duration(days: daysBefore));
  }
  return reminder;
}

/// Stable positive notification id derived from bill UUID.
int notificationIdForBill(String billId) => billId.hashCode & 0x7fffffff;

class ReminderService {
  ReminderService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    await _requestPermissions();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleMonthlyReminder({
    required int notificationId,
    required String billNickname,
    required int dayOfMonth,
    required String billId,
  }) async {
    await init();
    await _plugin.cancel(notificationId);

    final nextDue = computeNextReminderAt(dayOfMonth);
    final scheduled = tz.TZDateTime.from(nextDue, tz.local);

    await _plugin.zonedSchedule(
      notificationId,
      '💡 বিল বকেয়া আছে',
      '$billNickname — পেমেন্ট করতে ভুলবেন না',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bill_reminders',
          'বিল রিমাইন্ডার',
          channelDescription: 'মাসিক বিলের বকেয়া তারিখের রিমাইন্ডার',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'bill_id:$billId',
    );

    debugPrint(
      'Reminder scheduled for $billNickname at $scheduled (id=$notificationId)',
    );
  }

  /// Schedules a one-shot reminder after [delay] — useful for manual QA.
  Future<void> scheduleTestReminder({
    required String billNickname,
    required String billId,
    Duration delay = const Duration(minutes: 2),
  }) async {
    await init();
    final id = notificationIdForBill('test_$billId');
    await _plugin.cancel(id);
    final when = tz.TZDateTime.now(tz.local).add(delay);

    await _plugin.zonedSchedule(
      id,
      '💡 টেস্ট রিমাইন্ডার',
      '$billNickname — টেস্ট নোটিফিকেশন',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bill_reminders',
          'বিল রিমাইন্ডার',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'bill_id:$billId',
    );
    debugPrint('Test reminder in ${delay.inMinutes}m for $billNickname');
  }

  Future<void> cancelReminder(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

  Future<void> cancelForBill(String billId) async {
    await cancelReminder(notificationIdForBill(billId));
  }

  Future<void> rescheduleAll(List<BillAccount> accounts) async {
    await init();
    for (final account in accounts) {
      if (account.typicalDueDay == null) {
        await cancelForBill(account.id);
        continue;
      }
      await scheduleMonthlyReminder(
        notificationId: notificationIdForBill(account.id),
        billNickname: account.nickname,
        dayOfMonth: account.typicalDueDay!,
        billId: account.id,
      );
    }
  }

  Future<void> showImmediate({
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bill_reminders',
          'বিল রিমাইন্ডার',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});
