import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'api_service.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ── Notifications on/off preference ────────────────────────────────────
  static const FlutterSecureStorage _prefsStorage = FlutterSecureStorage();
  static const String _enabledKey = 'notifications_enabled';

  /// Whether the user has notifications turned on. Defaults to true if
  /// they've never touched the toggle.
  static Future<bool> areNotificationsEnabled() async {
    final value = await _prefsStorage.read(key: _enabledKey);
    return value != 'false';
  }

  /// Turns notifications on/off. Turning off immediately cancels every
  /// currently-scheduled local notification (checkup reminders, etc).
  /// Turning back on does NOT auto-reschedule old checkups — only
  /// checkups added or edited after re-enabling will get reminders again.
  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefsStorage.write(key: _enabledKey, value: enabled.toString());
    if (!enabled) {
      await _localNotifications.cancelAll();
    }
  }

  // Each checkup gets two notification ids derived from its own id, so we
  // can cancel/reschedule them individually without touching other checkups.
  // id 1001 -> day-before, id 2001 -> day-of, offset by checkup.id * 2.
  static int _dayBeforeId(int checkupId) => 1000 + (checkupId * 2);
  static int _dayOfId(int checkupId) => 1001 + (checkupId * 2);

  /// Sets up timezone data so zonedSchedule() has an accurate, current
  /// local timezone to work with. Call this once at app startup (in
  /// main(), before runApp()) — not just at login — so it always reflects
  /// the device's current timezone rather than a stale value cached from
  /// whenever the user last logged in.
  static Future<void> initializeTimeZoneData() async {
  tz_data.initializeTimeZones();
  final currentTimeZone = await FlutterTimezone.getLocalTimezone();
  print('🌍 Device timezone identifier: ${currentTimeZone.identifier}');
  tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));
  print('🌍 tz.local set to: ${tz.local.name}');
}

  /// Call this once, right after successful login (or app start once
  /// logged in). Sets up FCM and the local notification channel/permissions.
  /// Timezone setup no longer happens here — see initializeTimeZoneData(),
  /// which runs unconditionally in main() instead.
  static Future<void> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _localNotifications.initialize(initSettings);

    // Android 13+ requires a separate runtime permission for showing
    // notifications at all (this is different from FCM's requestPermission
    // above, which only covers push registration).
    //
    // NOTE: we no longer request the exact-alarms permission here.
    // Reminders are scheduled with AndroidScheduleMode.inexactAllowWhileIdle
    // (see scheduleCheckupReminders below), which does NOT require
    // USE_EXACT_ALARM / SCHEDULE_EXACT_ALARM at all — Play Console flags
    // apps that hold that permission unless their core function is an
    // alarm clock or calendar app, which FemCycle isn't. Inexact delivery
    // (typically within a few minutes of the scheduled time) is more than
    // sufficient for checkup reminders.
    if (Platform.isAndroid) {
      final androidImpl = _localNotifications
          .resolvePlatformSpecificImplementation
              <AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    }

    try {
      final String? token = await _messaging.getToken();
      print('FCM TOKEN: $token');
      if (token != null) {
        final result = await ApiService.updateDeviceToken(token);
        print('SEND TOKEN RESULT: $result');
      }
      _messaging.onTokenRefresh.listen(_sendTokenToBackend);
    } catch (e) {
      print('FCM registration error: $e');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Respect the toggle for push notifications too, not just local
      // scheduled ones — if the user turned notifications off, don't
      // surface incoming FCM messages either.
      if (!await areNotificationsEnabled()) return;

      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'femcycle_channel',
              'FemCycle Notifications',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  static Future<void> _sendTokenToBackend(String token) async {
    await ApiService.updateDeviceToken(token);
  }

  /// Parses a "9:00 AM" / "14:30" style string into hour/minute.
  /// Returns null if it can't be parsed.
  static (int hour, int minute)? _parseTimeString(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final match =
        RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$').firstMatch(s);
    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final meridiem = match.group(3)?.toUpperCase();

    if (meridiem == 'PM' && hour != 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;

    if (hour > 23 || minute > 59) return null;
    return (hour, minute);
  }

  /// Schedules the two reminders for a checkup:
  /// - "Day before": exactly 24 hours before the appointment's scheduled
  ///   time (falls back to treating the appointment as noon if no time
  ///   was set on the checkup).
  /// - Day of: 2 hours before the checkup's time (falls back to 7:00 AM
  ///   if no time was set on the checkup).
  ///
  /// Any reminder time that has already passed (e.g. checkup added same-day,
  /// after the reminder window) is silently skipped rather than erroring —
  /// but logged either way, so you can tell scheduled vs. skipped from the
  /// console.
  /// If the user has notifications turned off, this is a no-op — nothing
  /// gets scheduled until they turn the toggle back on.
  static Future<void> scheduleCheckupReminders({
    required int checkupId,
    required String title,
    required DateTime date,
    required String time,
  }) async {
    print('📅 scheduleCheckupReminders called: id=$checkupId, date=$date, time=$time');
    if (checkupId == 0) {
      print('📅 Skipped — checkupId is 0');
      return;
    }

    if (!await areNotificationsEnabled()) {
      print('📅 Skipped — notifications are turned off');
      return;
    }

    // Always clear any existing reminders for this checkup first, so
    // editing a checkup's date/time doesn't leave stale duplicates behind.
    await cancelCheckupReminders(checkupId);

    final dateOnly = DateTime(date.year, date.month, date.day);
    final now = tz.TZDateTime.now(tz.local);

    // Parsed once, reused by both reminders — the actual appointment
    // date+time, falling back to noon if no time was set.
    final parsedTime = _parseTimeString(time);
    final appointmentDateTime = parsedTime != null
        ? tz.TZDateTime(
            tz.local, dateOnly.year, dateOnly.month, dateOnly.day,
            parsedTime.$1, parsedTime.$2,
          )
        : tz.TZDateTime(
            tz.local, dateOnly.year, dateOnly.month, dateOnly.day, 12, 0,
          );

    // ── "Day before" reminder — exactly 24 hours before the appointment ──
    final dayBeforeSchedule =
        appointmentDateTime.subtract(const Duration(hours: 24));
    print('📅 dayBeforeSchedule=$dayBeforeSchedule, now=$now, willFire=${dayBeforeSchedule.isAfter(now)}');
    if (dayBeforeSchedule.isAfter(now)) {
      await _localNotifications.zonedSchedule(
        _dayBeforeId(checkupId),
        'Check-up tomorrow',
        '$title is scheduled for tomorrow.',
        dayBeforeSchedule,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'femcycle_channel',
            'FemCycle Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      print('📅 Day-before SKIPPED — schedule=$dayBeforeSchedule is not after now=$now');
    }

    // ── Day-of reminder, 2 hours before the checkup time (or 7:00 AM) ──
    tz.TZDateTime dayOfSchedule;
    String dayOfBody;

    if (parsedTime != null) {
      dayOfSchedule = appointmentDateTime.subtract(const Duration(hours: 2));
      dayOfBody = '$title is today at $time.';
    } else {
      dayOfSchedule = tz.TZDateTime(
        tz.local, dateOnly.year, dateOnly.month, dateOnly.day, 7, 0,
      );
      dayOfBody = '$title is today.';
    }

    print('📅 dayOfSchedule=$dayOfSchedule, now=$now, willFire=${dayOfSchedule.isAfter(now)}');
    if (dayOfSchedule.isAfter(now)) {
      try {
        await _localNotifications.zonedSchedule(
          _dayOfId(checkupId),
          'Check-up today',
          dayOfBody,
          dayOfSchedule,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'femcycle_channel',
              'FemCycle Notifications',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('📅 zonedSchedule call for dayOf id=${_dayOfId(checkupId)} completed without throwing');
      } catch (e, st) {
        print('📅 zonedSchedule THREW: $e');
        print('📅 stack: $st');
      }
    } else {
      print('📅 Day-of SKIPPED — schedule=$dayOfSchedule is not after now=$now');
    }

    // Dump whatever is actually queued with the OS right now, so we can
    // confirm the alarm was really registered (not just that the call
    // didn't throw).
    try {
      final pending = await _localNotifications.pendingNotificationRequests();
      print('📅 pendingNotificationRequests count=${pending.length}');
      for (final p in pending) {
        print('📅   pending id=${p.id} title=${p.title} body=${p.body}');
      }
    } catch (e) {
      print('📅 pendingNotificationRequests THREW: $e');
    }
  }

  /// Cancels both reminders for a checkup. Call this on delete, and also
  /// before rescheduling on edit (scheduleCheckupReminders already does
  /// this internally).
  static Future<void> cancelCheckupReminders(int checkupId) async {
    if (checkupId == 0) return;
    await _localNotifications.cancel(_dayBeforeId(checkupId));
    await _localNotifications.cancel(_dayOfId(checkupId));
  }
}