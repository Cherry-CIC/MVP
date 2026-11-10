// ignore_for_file: subtype_of_sealed_class

import 'dart:async';
import 'dart:convert';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/services/firestore_service.dart';
import 'package:cherry_mvp/core/services/username_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/welcome/widgets/post_auth_username_gate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeUser implements User {
  @override
  final String uid;

  _FakeUser({required this.uid});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseAuth implements FirebaseAuth {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;

  _FakeDocumentSnapshot(this._data);

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  final Future<DocumentSnapshot<Map<String, dynamic>>> Function() getHandler;

  _FakeDocumentReference({
    required this.getHandler,
  });

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) => getHandler();

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final DocumentReference<Map<String, dynamic>> Function(String path) _docHandler;

  _FakeCollectionReference(this._docHandler);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _docHandler(path ?? '');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseFirestore implements FirebaseFirestore {
  final CollectionReference<Map<String, dynamic>> Function(String path) _collectionHandler;

  _FakeFirebaseFirestore(this._collectionHandler);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _collectionHandler(collectionPath);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UsernameService.resolveUsername', () {
    test('returns cached username immediately if present in UID-scoped cache', () async {
      SharedPreferences.setMockInitialValues({
        'username_cache_by_uid': jsonEncode({'user_1': 'cached_alice'}),
      });

      final result = await UsernameService.resolveUsername('user_1');
      expect(result.isSuccess, isTrue);
      expect(result.value, 'cached_alice');
    });

    test('returns fallback cached username if stored under global prefs with matching UID', () async {
      SharedPreferences.setMockInitialValues({
        FirestoreConstants.id: 'user_1',
        FirestoreConstants.username: 'legacy_alice',
      });

      final result = await UsernameService.resolveUsername('user_1');
      expect(result.isSuccess, isTrue);
      expect(result.value, 'legacy_alice');
    });

    test('fresh install: queries Firestore and caches existing username', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final fakeFirestore = _FakeFirebaseFirestore((collectionPath) {
        expect(collectionPath, FirestoreConstants.pathUserCollection);
        return _FakeCollectionReference((docId) {
          expect(docId, 'user_fresh');
          return _FakeDocumentReference(
            getHandler: () async => _FakeDocumentSnapshot({
              FirestoreConstants.username: 'fresh_alice',
              FirestoreConstants.email: 'alice@example.com',
            }),
          );
        });
      });

      final result = await UsernameService.resolveUsername(
        'user_fresh',
        firestore: fakeFirestore,
        preferences: prefs,
      );

      expect(result.isSuccess, isTrue);
      expect(result.value, 'fresh_alice');

      // Verify that SharedPreferences now caches it under both keys
      expect(prefs.getString(FirestoreConstants.username), 'fresh_alice');
      final cacheMap = jsonDecode(prefs.getString('username_cache_by_uid')!);
      expect(cacheMap['user_fresh'], 'fresh_alice');
    });

    test('fresh install: genuine first-time user without username returns success(null)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final fakeFirestore = _FakeFirebaseFirestore((collectionPath) {
        return _FakeCollectionReference((docId) {
          return _FakeDocumentReference(
            getHandler: () async => _FakeDocumentSnapshot({
              FirestoreConstants.email: 'newuser@example.com',
            }),
          );
        });
      });

      final result = await UsernameService.resolveUsername(
        'user_new',
        firestore: fakeFirestore,
        preferences: prefs,
      );

      expect(result.isSuccess, isTrue);
      expect(result.value, isNull);
    });

    test('fresh install: Firestore timeout returns failure rather than null', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final fakeFirestore = _FakeFirebaseFirestore((collectionPath) {
        return _FakeCollectionReference((docId) {
          return _FakeDocumentReference(
            getHandler: () async {
              await Future.delayed(const Duration(milliseconds: 100));
              return _FakeDocumentSnapshot({});
            },
          );
        });
      });

      final result = await UsernameService.resolveUsername(
        'user_timeout',
        firestore: fakeFirestore,
        preferences: prefs,
        readTimeout: const Duration(milliseconds: 20),
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, isNotNull);
    });
  });

  group('FirestoreService cache sync', () {
    test('fetchUser updates both global username and username_cache_by_uid', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final fakeFirestore = _FakeFirebaseFirestore((collectionPath) {
        return _FakeCollectionReference((docId) {
          return _FakeDocumentReference(
            getHandler: () async => _FakeDocumentSnapshot({
              FirestoreConstants.id: 'user_sync',
              FirestoreConstants.username: 'synced_user',
              FirestoreConstants.firstname: 'Synced',
            }),
          );
        });
      });

      final firestoreService = FirestoreService(
        firebaseFirestore: fakeFirestore,
        prefs: prefs,
        firebaseAuth: _FakeFirebaseAuth(),
      );

      final result = await firestoreService.fetchUser('user_sync');
      expect(result.isSuccess, isTrue);

      expect(prefs.getString(FirestoreConstants.username), 'synced_user');
      final cacheMap = jsonDecode(prefs.getString('username_cache_by_uid')!);
      expect(cacheMap['user_sync'], 'synced_user');
    });
  });

  group('PostAuthUsernameGate Widget', () {
    Widget createWidget({
      required Future<Result<String?>> Function(String uid) resolver,
      User? user,
      Future<void> Function()? onSignOut,
    }) {
      return MultiProvider(
        providers: [
          Provider<NavigationProvider>(create: (_) => NavigationProvider()),
        ],
        child: MaterialApp(
          home: PostAuthUsernameGate(
            currentUserOverride: user ?? _FakeUser(uid: 'test_uid'),
            usernameResolver: resolver,
            signOutHandler: onSignOut,
            homeBuilder: (_) => const Scaffold(body: Text('HomePageMock')),
            usernameSetupBuilder: (_) => const Scaffold(body: Text('UsernameSetupPageMock')),
          ),
        ),
      );
    }

    testWidgets('shows loading indicator while resolving', (tester) async {
      final completer = Completer<Result<String?>>();

      await tester.pumpWidget(
        createWidget(resolver: (_) => completer.future),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('post_auth_error_title')), findsNothing);

      completer.complete(Result.success('alice'));
      await tester.pumpAndSettle();

      expect(find.text('HomePageMock'), findsOneWidget);
    });

    testWidgets('routes to HomePage when username is found', (tester) async {
      await tester.pumpWidget(
        createWidget(resolver: (_) async => Result.success('alice')),
      );
      await tester.pumpAndSettle();

      expect(find.text('HomePageMock'), findsOneWidget);
      expect(find.text('UsernameSetupPageMock'), findsNothing);
      expect(find.byKey(const Key('post_auth_error_title')), findsNothing);
    });

    testWidgets('routes to UsernameSetupPage for genuine new user without username', (tester) async {
      await tester.pumpWidget(
        createWidget(resolver: (_) async => Result.success(null)),
      );
      await tester.pumpAndSettle();

      expect(find.text('UsernameSetupPageMock'), findsOneWidget);
      expect(find.text('HomePageMock'), findsNothing);
      expect(find.byKey(const Key('post_auth_error_title')), findsNothing);
    });

    testWidgets('shows error and retry state on failure, does NOT show UsernameSetupPage', (tester) async {
      int attempts = 0;

      await tester.pumpWidget(
        createWidget(
          resolver: (_) async {
            attempts += 1;
            if (attempts == 1) {
              return Result.failure('Connection timeout');
            }
            return Result.success('recovered_user');
          },
        ),
      );
      await tester.pumpAndSettle();

      // Crucial assertion: Must NOT send the user to UsernameSetupPage on error!
      expect(find.text('UsernameSetupPageMock'), findsNothing);
      expect(find.text('HomePageMock'), findsNothing);
      expect(find.byKey(const Key('post_auth_error_title')), findsOneWidget);
      expect(find.byKey(const Key('post_auth_retry_button')), findsOneWidget);
      expect(find.byKey(const Key('post_auth_sign_out_button')), findsOneWidget);

      // Tap "Try Again"
      await tester.tap(find.byKey(const Key('post_auth_retry_button')));
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(find.text('HomePageMock'), findsOneWidget);
    });

    testWidgets('tapping sign out invokes sign out handler', (tester) async {
      bool signedOut = false;

      await tester.pumpWidget(
        createWidget(
          resolver: (_) async => Result.failure('Offline'),
          onSignOut: () async {
            signedOut = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('post_auth_sign_out_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('post_auth_sign_out_button')));
      await tester.pumpAndSettle();

      expect(signedOut, isTrue);
    });
  });
}
