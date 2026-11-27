import 'dart:async';

import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/notifications/locker_push_host.dart';
import 'package:cherry_mvp/features/notifications/push_messaging_gateway.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _User extends Fake implements User {
  _User(this.uid);
  @override
  final String uid;
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? currentUser = _User('buyer');
  final changes = StreamController<User?>.broadcast();
  @override
  Stream<User?> authStateChanges() => changes.stream;
}

class _Messages extends Fake implements PushMessagingGateway {
  final foreground = StreamController<Map<String, dynamic>>.broadcast();
  final opened = StreamController<Map<String, dynamic>>.broadcast();
  Map<String, dynamic>? initial;

  @override
  Stream<Map<String, dynamic>> get foregroundMessages => foreground.stream;
  @override
  Stream<Map<String, dynamic>> get openedMessages => opened.stream;
  @override
  Future<Map<String, dynamic>?> initialMessage() async => initial;
}

class _Api extends Fake implements ApiService {
  final requests = <String>[];
  late Future<Result<dynamic>> Function() read;
  @override
  Future<Result<T>> get<T>(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    requests.add(endpoint);
    final result = await read();
    return result.isSuccess
        ? Result.success(result.value as T)
        : Result.failure(result.error, statusCode: result.statusCode);
  }
}

void main() {
  const event = {
    'notificationType': 'locker_ready',
    'entityType': 'order',
    'entityId': 'order-1',
    'notificationId': 'event-1',
  };
  late bool alertsEnabled;
  late _Auth auth;
  late _Api api;
  late _Messages messages;
  late Map<String, dynamic> order;
  setUp(() {
    alertsEnabled = true;
    auth = _Auth();
    messages = _Messages();
    order = {
      'id': 'order-1',
      'userId': 'buyer',
      'productName': 'Green jumper',
      'paymentStatus': 'succeeded',
      'deliveryType': 'pickup_point',
      'deliveryState': 'shipped',
      'deliveryLabel': 'On the way',
      'shipment': {
        'status': 'en_route',
        'pickupPoint': {'name': 'Station locker'},
      },
    };
    api = _Api()
      ..read = () async => Result.success({
        'success': true,
        'data': {'order': order},
      });
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FirebaseAuth>.value(value: auth),
          Provider<ApiService>.value(value: api),
        ],
        child: MaterialApp(
          home: LockerPushHost(
            gateway: messages,
            userId: 'buyer',
            foregroundAlertsEnabled: () => alertsEnabled,
            child: const Scaffold(body: Text('Home')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a foreground event shows one banner and refetches the buyer order on tap', (tester) async {
    await mount(tester);
    messages.foreground.add(event);
    messages.foreground.add(event);
    await tester.pumpAndSettle();
    expect(find.text('View order'), findsOneWidget);
    expect(api.requests, ['/api/order/order-1']);
    await tester.tap(find.text('View order'));
    await tester.pumpAndSettle();
    expect(find.text('Green jumper'), findsOneWidget);
    expect(find.textContaining('Station locker'), findsOneWidget);
    expect(api.requests, ['/api/order/order-1', '/api/order/order-1']);
  });

  testWidgets('opt-out skips foreground lookups and still allows an intentional tap', (tester) async {
    alertsEnabled = false;
    await mount(tester);
    messages.foreground.add(event);
    await tester.pumpAndSettle();
    expect(api.requests, isEmpty);
    expect(find.text('View order'), findsNothing);

    messages.opened.add(event);
    await tester.pumpAndSettle();
    expect(api.requests, ['/api/order/order-1']);
    expect(find.text('Green jumper'), findsOneWidget);
  });

  testWidgets('opting out during an order lookup suppresses the foreground banner', (tester) async {
    final pending = Completer<Result<dynamic>>();
    final response = api.read;
    api.read = () => pending.future;
    await mount(tester);
    messages.foreground.add(event);
    await tester.pump();
    expect(api.requests, ['/api/order/order-1']);
    alertsEnabled = false;
    pending.complete(await response());
    await tester.pumpAndSettle();
    expect(find.text('View order'), findsNothing);
  });

  testWidgets('cold-start and repeated background taps open one current order', (tester) async {
    order['deliveryState'] = 'awaiting_confirmation';
    order['deliveryLabel'] = 'Awaiting your confirmation';
    messages.initial = event;
    await mount(tester);
    messages.opened.add(event);
    await tester.pumpAndSettle();
    expect(find.text('Awaiting your confirmation'), findsOneWidget);
    expect(find.textContaining('collection code'), findsNothing);
    expect(api.requests.length, 1);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('suppresses closed orders and other accounts in the foreground', (tester) async {
    order['deliveryState'] = 'confirmed';
    await mount(tester);
    messages.foreground.add(event);
    await tester.pumpAndSettle();
    order['deliveryState'] = 'shipped';
    order['userId'] = 'another-buyer';
    messages.foreground.add({...event, 'notificationId': 'another'});
    await tester.pumpAndSettle();
    expect(find.text('View order'), findsNothing);
  });

  testWidgets('an unauthorised or mismatched response never displays the order', (tester) async {
    order['userId'] = 'different-user';
    messages.initial = event;
    await mount(tester);
    expect(find.textContaining('unavailable for this account'), findsOneWidget);
    expect(find.text('Green jumper'), findsNothing);
  });

  testWidgets('a network failure on tap offers a retry', (tester) async {
    final success = api.read;
    api.read = () async => Result.failure('Offline');
    messages.initial = event;
    await mount(tester);
    expect(find.text('Try again'), findsOneWidget);
    api.read = success;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Green jumper'), findsOneWidget);
  });

  testWidgets('ignores unknown events and path segments', (tester) async {
    await mount(tester);
    messages.opened.add({...event, 'entityType': 'shipment'});
    messages.foreground.add({...event, 'entityId': '..'});
    await tester.pumpAndSettle();
    expect(api.requests, isEmpty);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('account change during lookup clears the open destination', (tester) async {
    final pending = Completer<Result<dynamic>>();
    api.read = () => pending.future;
    await mount(tester);
    messages.opened.add(event);
    await tester.pump();
    auth.currentUser = _User('next');
    auth.changes.add(auth.currentUser);
    pending.complete(
      Result.success({
        'success': true,
        'data': {'order': order},
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Green jumper'), findsNothing);
    expect(find.text('Your order'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });
}
