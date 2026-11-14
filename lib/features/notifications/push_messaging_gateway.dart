import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

enum PushPermission { notDetermined, denied, allowed }

abstract interface class PushMessagingGateway {
  bool get supported;
  String get platform;
  Stream<String> get tokenChanges;
  Stream<Map<String, dynamic>> get foregroundMessages;
  Stream<Map<String, dynamic>> get openedMessages;
  Future<Map<String, dynamic>?> initialMessage();
  Future<void> configure();
  Future<PushPermission> permission({bool request = false});
  Future<String?> token();
  Future<void> deleteToken();
}

class FirebasePushMessagingGateway implements PushMessagingGateway {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  @override
  bool get supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
  @override
  String get platform => defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  @override
  Stream<String> get tokenChanges => _messaging.onTokenRefresh;
  @override
  Stream<Map<String, dynamic>> get foregroundMessages => FirebaseMessaging.onMessage.map((m) => m.data);
  @override
  Stream<Map<String, dynamic>> get openedMessages => FirebaseMessaging.onMessageOpenedApp.map((m) => m.data);
  @override
  Future<Map<String, dynamic>?> initialMessage() async => (await _messaging.getInitialMessage())?.data;
  @override
  Future<void> configure() async {
    // Token creation stays explicit, after the buyer opts in. Do not display
    // another system banner while the in-app reminder is available.
    await _messaging.setAutoInitEnabled(false);
    await _messaging.setForegroundNotificationPresentationOptions(alert: false, badge: false, sound: false);
  }

  @override
  Future<PushPermission> permission({bool request = false}) async {
    final settings = request
        ? await _messaging.requestPermission(alert: true, badge: false, sound: true)
        : await _messaging.getNotificationSettings();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized || AuthorizationStatus.provisional => PushPermission.allowed,
      AuthorizationStatus.denied => PushPermission.denied,
      AuthorizationStatus.notDetermined => PushPermission.notDetermined,
    };
  }

  @override
  Future<String?> token() async {
    // Firebase requires APNs registration to finish before requesting an FCM
    // token on iOS. The controller retries on foregrounding and shortly after
    // opt-in if registration is still in progress.
    if (platform == 'ios' && await _messaging.getAPNSToken() == null) return null;
    return _messaging.getToken();
  }

  @override
  Future<void> deleteToken() => _messaging.deleteToken();
}
