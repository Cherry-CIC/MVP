import 'dart:async';
import 'package:cherry_mvp/features/notifications/notification_device_repository.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class Auth extends Fake implements FirebaseAuth {
  @override
  User? currentUser;
}

class Buyer extends Fake implements User {
  Buyer(this.uid);
  @override
  final String uid;
  Completer<String?>? pending;
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => pending?.future ?? 'bearer-$uid';
}

void main() {
  late Auth auth;
  late Dio dio;
  late ApiNotificationDeviceRepository repository;
  late List<RequestOptions> requests;
  setUp(() {
    auth = Auth()..currentUser = Buyer('buyer');
    requests = [];
    dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(Response(requestOptions: options, statusCode: 200, data: {'success': true}));
        },
      ),
    );
    repository = ApiNotificationDeviceRepository(auth: auth, dio: dio);
  });
  tearDown(() => dio.close());
  test('registration uses captured buyer bearer and sends no user-controlled owner', () async {
    expect(await repository.register(userId: 'buyer', token: 'token', platform: 'ios'), isTrue);
    expect(requests.single.path, '/api/notifications/devices');
    expect(requests.single.headers['Authorization'], 'Bearer bearer-buyer');
    expect(requests.single.data, {'token': 'token', 'platform': 'ios'});
  });
  test('rejects another account registration and revocation locally', () async {
    expect(await repository.register(userId: 'other', token: 'token', platform: 'ios'), isFalse);
    expect(await repository.unregister(userId: 'other', token: 'token'), isFalse);
    expect(requests, isEmpty);
  });
  test('account switch while refreshing bearer cannot register under a new owner', () async {
    final buyer = auth.currentUser! as Buyer;
    buyer.pending = Completer<String?>();
    final request = repository.register(userId: 'buyer', token: 'token', platform: 'ios');
    auth.currentUser = Buyer('other');
    buyer.pending!.complete('old-bearer');
    expect(await request, isFalse);
    expect(requests, isEmpty);
  });
  test('logout while refreshing bearer cannot revoke another account device', () async {
    final buyer = auth.currentUser! as Buyer;
    buyer.pending = Completer<String?>();
    final request = repository.unregister(userId: 'buyer', token: 'token');
    auth.currentUser = null;
    buyer.pending!.complete('old-bearer');
    expect(await request, isFalse);
    expect(requests, isEmpty);
  });
  test('rollout-disabled and offline failures return a safe unsuccessful result', () async {
    dio.interceptors.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 503),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );
    expect(await repository.register(userId: 'buyer', token: 'token', platform: 'ios'), isFalse);
  });
  test('revocation uses DELETE with the existing buyer bearer', () async {
    expect(await repository.unregister(userId: 'buyer', token: 'token'), isTrue);
    expect(requests.single.method, 'DELETE');
    expect(requests.single.data, {'token': 'token'});
    expect(requests.single.headers['Authorization'], 'Bearer bearer-buyer');
  });
}
