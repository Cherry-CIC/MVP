import 'dart:async';
import 'package:cherry_mvp/features/notifications/collection_notification_inbox.dart';
import 'package:cherry_mvp/features/notifications/collection_notification_settings.dart';
import 'package:cherry_mvp/features/notifications/collection_push_controller.dart';
import 'package:cherry_mvp/features/notifications/notification_device_repository.dart';
import 'package:cherry_mvp/features/notifications/push_messaging_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> message({String uid = 'buyer', String event = 'event'}) => {
  'type': 'ready_to_collect',
  'userId': uid,
  'orderId': 'order',
  'eventId': event,
};

class Gateway implements PushMessagingGateway {
  @override
  bool supported = true;
  @override
  String platform = 'android';
  final tokens = StreamController<String>.broadcast(sync: true);
  final foreground = StreamController<Map<String, dynamic>>.broadcast(sync: true);
  final opened = StreamController<Map<String, dynamic>>.broadcast(sync: true);
  PushPermission status = PushPermission.allowed;
  String? deviceToken = 'token-a';
  Map<String, dynamic>? initial;
  bool deleteFails = false;
  int requests = 0;
  int tokenRequests = 0;
  int deletes = 0;
  @override
  Stream<String> get tokenChanges => tokens.stream;
  @override
  Stream<Map<String, dynamic>> get foregroundMessages => foreground.stream;
  @override
  Stream<Map<String, dynamic>> get openedMessages => opened.stream;
  @override
  Future<void> configure() async {}
  @override
  Future<Map<String, dynamic>?> initialMessage() async => initial;
  @override
  Future<PushPermission> permission({bool request = false}) async {
    if (request) requests++;
    return status;
  }

  @override
  Future<String?> token() async {
    tokenRequests++;
    return deviceToken;
  }

  @override
  Future<void> deleteToken() async {
    deletes++;
    if (deleteFails) throw StateError('Offline');
  }
}

class Devices implements NotificationDeviceRepository {
  final registrations = <String>[];
  final removals = <String>[];
  bool succeeds = true;
  Completer<bool>? pending;
  @override
  Future<bool> register({required String userId, required String token, required String platform}) async {
    registrations.add('$userId:$token:$platform');
    return pending?.future ?? succeeds;
  }

  @override
  Future<bool> unregister({required String userId, required String token}) async {
    removals.add('$userId:$token');
    return succeeds;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Gateway gateway;
  late Devices devices;
  late SharedPreferences prefs;
  late StreamController<String?> accounts;
  late CollectionNotificationInbox inbox;
  late CollectionPushController controller;
  String? uid;
  Future<void> start({Map<String, Object> saved = const {}}) async {
    SharedPreferences.setMockInitialValues(saved);
    prefs = await SharedPreferences.getInstance();
    gateway = Gateway();
    devices = Devices();
    accounts = StreamController<String?>.broadcast(sync: true);
    inbox = CollectionNotificationInbox();
    uid = 'buyer';
    controller = CollectionPushController(
      gateway: gateway,
      repository: devices,
      preferences: prefs,
      currentUserId: () => uid,
      accountChanges: accounts.stream,
      inbox: inbox,
    );
    await controller.refresh();
    await Future<void>.delayed(Duration.zero);
  }

  tearDown(() async {
    controller.dispose();
    inbox.dispose();
    await accounts.close();
    await gateway.tokens.close();
    await gateway.foreground.close();
    await gateway.opened.close();
  });
  test('launch does not ask permission or register until buyer opts in', () async {
    await start();
    expect(gateway.requests, 0);
    expect(gateway.tokenRequests, 0);
    expect(devices.registrations, isEmpty);
    await controller.setEnabled(true);
    expect(gateway.requests, 1);
    expect(controller.registered, isTrue);
    expect(devices.registrations, contains('buyer:token-a:android'));
  });
  test('denied permission leaves reminders independent and gives settings guidance', () async {
    await start();
    gateway.status = PushPermission.denied;
    await controller.setEnabled(true);
    expect(controller.enabled, isFalse);
    expect(devices.registrations, isEmpty);
    expect(controller.error, contains('phone settings'));
  });
  test('rollout-disabled registration is nonblocking and can retry', () async {
    await start();
    devices.succeeds = false;
    await controller.setEnabled(true);
    expect(controller.enabled, isTrue);
    expect(controller.registered, isFalse);
    expect(controller.error, contains('reminders still work'));
    devices.succeeds = true;
    await controller.refresh();
    expect(controller.registered, isTrue);
    expect(controller.error, isNull);
  });
  test('refreshing a token removes its previous registration', () async {
    await start();
    await controller.setEnabled(true);
    gateway.deviceToken = 'token-b';
    gateway.tokens.add('token-b');
    await controller.refresh();
    expect(devices.removals, contains('buyer:token-a'));
    expect(devices.registrations.last, 'buyer:token-b:android');
  });
  test('revoked phone permission removes registration without requesting again', () async {
    await start();
    await controller.setEnabled(true);
    gateway.status = PushPermission.denied;
    await controller.refresh();
    expect(devices.removals, contains('buyer:token-a'));
    expect(gateway.deletes, 1);
    expect(controller.registered, isFalse);
    expect(gateway.requests, 1);
    expect(controller.error, contains('phone settings'));
    gateway.status = PushPermission.allowed;
    await controller.refresh();
    expect(controller.registered, isTrue);
    expect(controller.error, isNull);
  });
  test('offline logout retains a rotation marker and blocks another account until cleanup', () async {
    await start();
    await controller.setEnabled(true);
    gateway.deleteFails = true;
    await controller.beforeSignOut();
    expect(prefs.getBool('collectionPush.rotate'), isTrue);
    uid = 'other';
    accounts.add(uid);
    await prefs.setBool('collectionPush.enabled.other', true);
    await controller.refresh();
    expect(devices.registrations.every((r) => r.startsWith('buyer:')), isTrue);
    gateway.deleteFails = false;
    gateway.deviceToken = 'token-new';
    await controller.refresh();
    expect(devices.registrations.last, 'other:token-new:android');
    expect(prefs.getBool('collectionPush.rotate'), isNull);
  });
  test('logout waits for an in-flight registration then revokes it', () async {
    await start();
    await prefs.setBool('collectionPush.enabled.buyer', true);
    devices.pending = Completer<bool>();
    final registration = controller.refresh();
    await Future<void>.delayed(Duration.zero);
    final logout = controller.beforeSignOut();
    devices.pending!.complete(true);
    await registration;
    await logout;
    expect(devices.removals, contains('buyer:token-a'));
    expect(controller.registered, isFalse);
    expect(prefs.getString('collectionPush.token'), isNull);
  });
  test('foreground delivery refreshes while a tap is retained only for its buyer', () async {
    await start();
    int hints = 0;
    inbox.addListener(() => hints++);
    gateway.foreground.add(message());
    expect(hints, 1);
    expect(inbox.pendingFor('buyer'), isNull);
    gateway.opened.add(message());
    expect(inbox.pendingFor('buyer')?.orderId, 'order');
    gateway.opened.add(message());
    expect(hints, 2);
    uid = 'other';
    accounts.add(uid);
    await controller.refresh();
    expect(inbox.pendingFor('other'), isNull);
    gateway.opened.add(message(event: 'another'));
    expect(inbox.pendingFor('other'), isNull);
  });
  test('cold launch intent waits for matching authentication and rejects malformed payloads', () async {
    await start();
    final pending = CollectionNotificationInbox();
    pending.receive(message(), opened: true);
    expect(pending.pendingFor('buyer'), isNull);
    pending.setUser('buyer');
    expect(pending.pendingFor('buyer'), isNotNull);
    pending.setUser('other');
    expect(pending.pendingFor('other'), isNull);
    expect(CollectionNotification.parse({...message(), 'orderId': '../order'}), isNull);
    expect(CollectionNotification.parse({...message(), 'type': 'unrecognised'}), isNull);
    pending.dispose();
  });
  testWidgets('notification settings have a labelled switch and fit large text', (tester) async {
    await tester.runAsync(start);
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const Scaffold(body: SingleChildScrollView(child: CollectionNotificationSettings())),
          ),
        ),
      ),
    );
    expect(find.text('Collection notifications'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
