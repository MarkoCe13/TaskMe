import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    print('NotificationService.init() START');
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings);
    print('NotificationService.init() DONE');

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  int notifIdFromDocId(String docId) => docId.hashCode;

  Future<void> debugPending() async {
  final pending = await _plugin.pendingNotificationRequests();
  print('PENDING NOTIFICATIONS: ${pending.length}');
  for (final p in pending) {
    print('  - id=${p.id}, title=${p.title}, body=${p.body}');
  }
}


  Future<void> scheduleDeadlineReminder({
    required String docId,
    required String title,
    required DateTime deadline,
    Duration before = const Duration(minutes: 30),
  }) async {
    final when = deadline.subtract(before);

    if (!when.isAfter(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'deadlines',
      'Deadlines',
      channelDescription: 'Deadline reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      notifIdFromDocId(docId),
      'Deadline soon',
      '“$title” is due in ${before.inMinutes} minutes.',
      tz.TZDateTime.from(when, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelForDocId(String docId) async {
    await _plugin.cancel(notifIdFromDocId(docId));
  }
}
