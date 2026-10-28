import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/shared_preferences_provider.dart';

/// Where the unread count lives. The background isolate writes it too, so it
/// is a plain preferences key rather than in-memory state.
const badgeCountKey = 'notification_badge';

final _localNotifications = FlutterLocalNotificationsPlugin();

/// Must match `default_notification_channel_id` in AndroidManifest.xml, so a
/// push that names no channel lands in the same place as a local one.
///
/// Android locks a channel's sound in at creation and ignores changes to an
/// existing channel of the same id, so the tone below only takes effect
/// because this id is new — bump it again if the tone ever needs to change.
const _channel = AndroidNotificationChannel(
  'apna_service_partner_jobs',
  'Job updates',
  description: 'New job requests and status changes.',
  importance: Importance.high,
  sound: RawResourceAndroidNotificationSound('job_alert_tone'),
);

/// Android only shows a push by itself when the app is backgrounded, so a
/// foreground message is drawn locally instead.
Future<void> showMessageNotification(RemoteMessage message) async {
  final notification = message.notification;
  final title = notification?.title ?? message.data['title'] as String?;
  final body = notification?.body ?? message.data['body'] as String?;
  if (title == null && body == null) return;

  try {
    await _localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          sound: _channel.sound,
        ),
      ),
    );
  } catch (error) {
    debugPrint('Could not show notification: $error');
  }
}

/// Registers the channel the manifest points at. Safe to call again from the
/// background isolate, which starts with a fresh plugin instance.
Future<void> _setUpLocalNotificationsChannel() async {
  await _localNotifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(_channel);
}

/// Pushes [count] to the launcher icon. Badges are launcher-dependent on
/// Android, so an unsupported device is not an error.
Future<void> applyAppBadge(int count) async {
  try {
    if (await AppBadgePlus.isSupported()) {
      await AppBadgePlus.updateBadge(count);
    }
  } catch (error) {
    debugPrint('Badge update failed: $error');
  }
}

/// Runs in its own isolate when a message arrives with the app backgrounded
/// or killed, so the badge keeps counting while the UI is gone.
@pragma('vm:entry-point')
Future<void> pushBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  final next = (prefs.getInt(badgeCountKey) ?? 0) + 1;
  await prefs.setInt(badgeCountKey, next);
  await applyAppBadge(next);

  // Android draws a `notification` payload itself; a data-only one is ours
  // to show, or nothing would appear.
  if (message.notification == null) {
    await _setUpLocalNotificationsChannel();
    await showMessageNotification(message);
  }
}

/// The unread notification count shown on the app icon and the bell.
class BadgeCount extends Notifier<int> {
  @override
  int build() => ref.read(sharedPreferencesProvider).getInt(badgeCountKey) ?? 0;

  Future<void> increment() => _write(state + 1);

  Future<void> clear() => _write(0);

  /// Picks up whatever the background isolate wrote while the UI was away.
  Future<void> reload() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.reload();
    state = prefs.getInt(badgeCountKey) ?? 0;
    await applyAppBadge(state);
  }

  Future<void> _write(int value) async {
    await ref.read(sharedPreferencesProvider).setInt(badgeCountKey, value);
    state = value;
    await applyAppBadge(value);
  }
}

final badgeCountProvider = NotifierProvider<BadgeCount, int>(BadgeCount.new);

/// Bumped on every push received in the foreground or tapped open, so any
/// provider watching it (the bookings feed) knows to refetch.
class PushRefreshSignal extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final pushRefreshProvider = NotifierProvider<PushRefreshSignal, int>(
  PushRefreshSignal.new,
);

/// Reads the FCM registration token, which login sends to the API.
class PushTokens {
  const PushTokens();

  /// Returns an empty string when messaging is unavailable — on an emulator
  /// without Play Services, say — so sign-in still goes through.
  Future<String> read() async {
    try {
      return await FirebaseMessaging.instance.getToken() ?? '';
    } catch (error) {
      debugPrint('FCM token unavailable: $error');
      return '';
    }
  }
}

final pushTokensProvider = Provider<PushTokens>((ref) => const PushTokens());

/// Firebase setup, called once from `main`.
class PushService {
  const PushService._();

  static Future<void> initialize(ProviderContainer container) async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(pushBackgroundHandler);
      await FirebaseMessaging.instance.requestPermission();
      await _setUpLocalNotificationsChannel();
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      final badge = container.read(badgeCountProvider.notifier);
      final refresh = container.read(pushRefreshProvider.notifier);
      FirebaseMessaging.onMessage.listen((message) async {
        await badge.increment();
        await showMessageNotification(message);
        // A new job, a status change, etc. — the bookings feed is stale.
        refresh.bump();
      });
      // Opening the app from a notification clears what it was counting.
      FirebaseMessaging.onMessageOpenedApp.listen((_) {
        badge.clear();
        refresh.bump();
      });

      await badge.reload();

      if (kDebugMode) {
        // Handy when sending a test push from the Firebase console.
        debugPrint('FCM token: ${await const PushTokens().read()}');
      }
    } catch (error) {
      // No Firebase config, no Play Services, no network: the app still runs,
      // just without push.
      debugPrint('Push setup skipped: $error');
    }
  }
}
