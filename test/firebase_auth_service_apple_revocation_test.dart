import 'dart:convert';

import 'package:cherry_mvp/core/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeUserInfo implements UserInfo {
  @override
  final String providerId;

  _FakeUserInfo(this.providerId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAdditionalUserInfo implements AdditionalUserInfo {
  @override
  final String? authorizationCode;

  _FakeAdditionalUserInfo({this.authorizationCode});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOAuthCredential extends OAuthCredential {
  _FakeOAuthCredential({super.accessToken})
    : super(
        providerId: 'apple.com',
        signInMethod: 'oauth',
      );
}

class _FakeUserCredential implements UserCredential {
  @override
  final AdditionalUserInfo? additionalUserInfo;

  @override
  final AuthCredential? credential;

  _FakeUserCredential({this.additionalUserInfo, this.credential});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  @override
  final List<UserInfo> providerData;

  final Future<UserCredential> Function(AuthProvider provider)? reauthHandler;
  final String? idToken;
  int reauthWithProviderCalls = 0;
  int reauthWithPopupCalls = 0;

  _FakeUser({
    required this.providerData,
    this.reauthHandler,
    this.idToken = 'fake-firebase-id-token',
  });

  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) {
    reauthWithProviderCalls += 1;
    if (reauthHandler != null) {
      return reauthHandler!(provider);
    }
    throw StateError('reauthHandler not configured');
  }

  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) {
    reauthWithPopupCalls += 1;
    if (reauthHandler != null) {
      return reauthHandler!(provider);
    }
    throw StateError('reauthHandler not configured');
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => idToken;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseApp implements FirebaseApp {
  final String apiKey;

  _FakeFirebaseApp({this.apiKey = 'test-firebase-api-key'});

  @override
  FirebaseOptions get options => FirebaseOptions(
    apiKey: apiKey,
    appId: 'test-app-id',
    messagingSenderId: 'test-sender-id',
    projectId: 'test-project-id',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestFirebaseAuth implements FirebaseAuth {
  _FakeUser? user;
  int revokeCalls = 0;
  String? lastRevokedCode;
  int revokeAccessTokenCalls = 0;
  String? lastRevokedAccessToken;
  Exception? revokeError;
  List<Exception?> revokeErrorsSequence = [];
  Future<void> Function(String code)? onRevokeWithCode;
  @override
  FirebaseApp app;
  @override
  String? tenantId;

  _TestFirebaseAuth({this.user, FirebaseApp? app, this.tenantId})
    : app = app ?? _FakeFirebaseApp();

  @override
  User? get currentUser => user;

  @override
  Future<void> revokeTokenWithAuthorizationCode(String authorizationCode) async {
    revokeCalls += 1;
    lastRevokedCode = authorizationCode;
    if (onRevokeWithCode != null) {
      await onRevokeWithCode!(authorizationCode);
    }
    if (revokeErrorsSequence.isNotEmpty) {
      final err = revokeErrorsSequence.removeAt(0);
      if (err != null) {
        throw err;
      }
      return;
    }
    if (revokeError != null) {
      throw revokeError!;
    }
  }

  @override
  Future<void> revokeAccessToken(String accessToken) async {
    revokeAccessTokenCalls += 1;
    lastRevokedAccessToken = accessToken;
    if (revokeErrorsSequence.isNotEmpty) {
      final err = revokeErrorsSequence.removeAt(0);
      if (err != null) {
        throw err;
      }
      return;
    }
    if (revokeError != null) {
      throw revokeError!;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;
  int requestCount = 0;
  Uri? lastUri;
  Map<String, dynamic>? lastJsonBody;

  _FakeHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestCount += 1;
    lastUri = request.url;
    if (request is http.Request && request.body.isNotEmpty) {
      lastJsonBody = jsonDecode(request.body) as Map<String, dynamic>;
    }
    final response = await handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('FirebaseAuthService Apple Revocation', () {
    test('isAppleLinked returns false if user is null', () {
      final auth = _TestFirebaseAuth(user: null);
      final service = FirebaseAuthService(firebaseAuth: auth);

      expect(service.isAppleLinked(), isFalse);
    });

    test('isAppleLinked returns false if user has no apple.com provider', () {
      final auth = _TestFirebaseAuth(
        user: _FakeUser(
          providerData: [_FakeUserInfo('google.com'), _FakeUserInfo('password')],
        ),
      );
      final service = FirebaseAuthService(firebaseAuth: auth);

      expect(service.isAppleLinked(), isFalse);
    });

    test('isAppleLinked returns true if user has apple.com provider', () {
      final auth = _TestFirebaseAuth(
        user: _FakeUser(
          providerData: [_FakeUserInfo('apple.com')],
        ),
      );
      final service = FirebaseAuthService(firebaseAuth: auth);

      expect(service.isAppleLinked(), isTrue);
    });

    test('revokeAppleAccessIfLinked returns skipped if user is null', () async {
      final auth = _TestFirebaseAuth(user: null);
      final service = FirebaseAuthService(firebaseAuth: auth);

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.skipped);
      expect(auth.revokeCalls, 0);
    });

    test('revokeAppleAccessIfLinked returns skipped if user not linked to Apple', () async {
      final auth = _TestFirebaseAuth(
        user: _FakeUser(
          providerData: [_FakeUserInfo('google.com')],
        ),
      );
      final service = FirebaseAuthService(firebaseAuth: auth);

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.skipped);
      expect(auth.revokeCalls, 0);
    });

    test('revokeAppleAccessIfLinked revokes token when authorization code is present', () async {
      final auth = _TestFirebaseAuth();
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => _FakeUserCredential(
          additionalUserInfo: _FakeAdditionalUserInfo(
            authorizationCode: 'valid-apple-auth-code-12345',
          ),
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        targetPlatform: TargetPlatform.iOS,
      );

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.success);
      expect(auth.revokeCalls, 1);
      expect(auth.lastRevokedCode, 'valid-apple-auth-code-12345');
    });

    test('revokeAppleAccessIfLinked returns userCancelled on user cancellation exception', () async {
      final auth = _TestFirebaseAuth();
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => throw FirebaseAuthException(
          code: 'canceled',
          message: 'The operation was canceled.',
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(firebaseAuth: auth);

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.userCancelled);
      expect(auth.revokeCalls, 0);
    });

    test('revokeAppleAccessIfLinked returns userCancelled on popup-closed-by-user', () async {
      final auth = _TestFirebaseAuth();
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => throw FirebaseAuthException(
          code: 'popup-closed-by-user',
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(firebaseAuth: auth);

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.userCancelled);
      expect(auth.revokeCalls, 0);
    });

    test('revokeAppleAccessIfLinked returns userCancelled on Android web-context-canceled', () async {
      final auth = _TestFirebaseAuth();
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => throw FirebaseAuthException(
          code: 'web-context-canceled',
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(firebaseAuth: auth);

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.userCancelled);
      expect(auth.revokeCalls, 0);
    });

    test('revokeAppleAccessIfLinked returns userCancelled on user-canceled', () async {
      final auth = _TestFirebaseAuth();
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => throw FirebaseAuthException(
          code: 'user-canceled',
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(firebaseAuth: auth);

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.userCancelled);
      expect(auth.revokeCalls, 0);
    });

    test('revokeAppleAccessIfLinked returns failedNonBlocking on technical error', () async {
      final auth = _TestFirebaseAuth();
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => throw FirebaseAuthException(
          code: 'network-request-failed',
          message: 'Network error',
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(firebaseAuth: auth);

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.failedNonBlocking);
      expect(auth.revokeCalls, 0);
    });

    test('revokeAppleAccessIfLinked returns failedNonBlocking if authorizationCode is null/empty', () async {
      final auth = _TestFirebaseAuth();
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => _FakeUserCredential(
          additionalUserInfo: _FakeAdditionalUserInfo(authorizationCode: null),
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        targetPlatform: TargetPlatform.iOS,
      );

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.failedNonBlocking);
      expect(auth.revokeCalls, 0);
    });

    test('revokeAppleAccessIfLinked returns failedNonBlocking if revoke call fails', () async {
      final auth = _TestFirebaseAuth();
      auth.revokeError = FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Revoke failed on server',
      );
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => _FakeUserCredential(
          additionalUserInfo: _FakeAdditionalUserInfo(
            authorizationCode: 'some-code',
          ),
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        targetPlatform: TargetPlatform.iOS,
      );

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.failedNonBlocking);
      expect(auth.revokeCalls, 1);
    });

    test('revokeAppleAccessIfLinked returns userCancelled on PlatformException with code 1001', () async {
      final auth = _TestFirebaseAuth();
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => throw PlatformException(
          code: '1001',
          message: 'The operation was canceled.',
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(firebaseAuth: auth);

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.userCancelled);
      expect(auth.revokeCalls, 0);
    });

    test('revokeAppleAccessIfLinked returns failedNonBlocking when revoke call fails with error containing cancel', () async {
      final auth = _TestFirebaseAuth();
      // Revoke error that happens to have the word "cancel" in it
      auth.revokeError = Exception('HTTP request cancelled by peer');
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => _FakeUserCredential(
          additionalUserInfo: _FakeAdditionalUserInfo(
            authorizationCode: 'valid-code',
          ),
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        targetPlatform: TargetPlatform.iOS,
      );

      final result = await service.revokeAppleAccessIfLinked();

      // Must be failedNonBlocking so it does not block account deletion!
      expect(result, RevokeAppleTokenResult.failedNonBlocking);
      expect(auth.revokeCalls, 1);
    });

    test('revokeAppleAccessIfLinked retries on transient error and succeeds if next attempt passes', () async {
      final auth = _TestFirebaseAuth();
      auth.revokeErrorsSequence = [
        FirebaseAuthException(code: 'network-request-failed'),
        null, // Succeeds on 2nd attempt
      ];
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => _FakeUserCredential(
          additionalUserInfo: _FakeAdditionalUserInfo(
            authorizationCode: 'valid-code',
          ),
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        targetPlatform: TargetPlatform.iOS,
        maxRevokeAttempts: 3,
        revokeRetryDelay: Duration.zero,
      );

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.success);
      expect(auth.revokeCalls, 2);
    });

    test('revokeAppleAccessIfLinked retries transient error up to maxAttempts and exhausts cleanly to failedNonBlocking', () async {
      final auth = _TestFirebaseAuth();
      auth.revokeErrorsSequence = [
        FirebaseAuthException(code: 'network-request-failed'),
        FirebaseAuthException(code: 'timeout'),
        FirebaseAuthException(code: 'internal-error'),
      ];
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => _FakeUserCredential(
          additionalUserInfo: _FakeAdditionalUserInfo(
            authorizationCode: 'valid-code',
          ),
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        targetPlatform: TargetPlatform.iOS,
        maxRevokeAttempts: 3,
        revokeRetryDelay: Duration.zero,
      );

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.failedNonBlocking);
      expect(auth.revokeCalls, 3);
    });

    test('revokeAppleAccessIfLinked does not retry non-transient errors', () async {
      final auth = _TestFirebaseAuth();
      auth.revokeError = FirebaseAuthException(code: 'invalid-credential');
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => _FakeUserCredential(
          additionalUserInfo: _FakeAdditionalUserInfo(
            authorizationCode: 'valid-code',
          ),
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        targetPlatform: TargetPlatform.iOS,
        maxRevokeAttempts: 3,
        revokeRetryDelay: Duration.zero,
      );

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.failedNonBlocking);
      expect(auth.revokeCalls, 1);
    });

    test('Android: revokes token using credential.accessToken and revokeAccessToken when authorizationCode is null', () async {
      final auth = _TestFirebaseAuth();
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => _FakeUserCredential(
          additionalUserInfo: _FakeAdditionalUserInfo(authorizationCode: null),
          credential: _FakeOAuthCredential(
            accessToken: 'android-apple-access-token-xyz',
          ),
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        targetPlatform: TargetPlatform.android,
      );

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.success);
      expect(auth.revokeAccessTokenCalls, 1);
      expect(auth.lastRevokedAccessToken, 'android-apple-access-token-xyz');
      expect(auth.revokeCalls, 0);
    });

    test('Android: returns failedNonBlocking when credential.accessToken is null or empty', () async {
      final auth = _TestFirebaseAuth();
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => _FakeUserCredential(
          additionalUserInfo: _FakeAdditionalUserInfo(authorizationCode: null),
          credential: _FakeOAuthCredential(accessToken: ''),
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        targetPlatform: TargetPlatform.android,
      );

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.failedNonBlocking);
      expect(auth.revokeAccessTokenCalls, 0);
      expect(auth.revokeCalls, 0);
    });

    test('Android: retries revokeAccessToken on transient error and succeeds on subsequent attempt', () async {
      final auth = _TestFirebaseAuth();
      auth.revokeErrorsSequence = [
        FirebaseAuthException(code: 'network-request-failed'),
        null,
      ];
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => _FakeUserCredential(
          additionalUserInfo: _FakeAdditionalUserInfo(authorizationCode: null),
          credential: _FakeOAuthCredential(
            accessToken: 'android-apple-access-token-retry',
          ),
        ),
      );
      auth.user = user;
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        targetPlatform: TargetPlatform.android,
        maxRevokeAttempts: 3,
        revokeRetryDelay: Duration.zero,
      );

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.success);
      expect(auth.revokeAccessTokenCalls, 2);
      expect(auth.lastRevokedAccessToken, 'android-apple-access-token-retry');
    });

    test('Web: reauthenticates with popup and revokes accessToken via Identity Toolkit endpoint', () async {
      final auth = _TestFirebaseAuth(
        app: _FakeFirebaseApp(apiKey: 'web-api-key-123'),
        tenantId: 'tenant-abc',
      );
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        idToken: 'web-firebase-id-token-999',
        reauthHandler: (_) async => _FakeUserCredential(
          additionalUserInfo: _FakeAdditionalUserInfo(authorizationCode: null),
          credential: _FakeOAuthCredential(
            accessToken: 'web-apple-access-token-456',
          ),
        ),
      );
      auth.user = user;
      final fakeHttp = _FakeHttpClient((_) async => http.Response('{}', 200));
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        isWeb: true,
        httpClient: fakeHttp,
      );

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.success);
      expect(user.reauthWithPopupCalls, 1);
      expect(user.reauthWithProviderCalls, 0);
      expect(fakeHttp.requestCount, 1);
      expect(
        fakeHttp.lastUri.toString(),
        'https://identitytoolkit.googleapis.com/v2/accounts:revokeToken?key=web-api-key-123',
      );
      expect(fakeHttp.lastJsonBody, <String, dynamic>{
        'providerId': 'apple.com',
        'tokenType': 'ACCESS_TOKEN',
        'token': 'web-apple-access-token-456',
        'idToken': 'web-firebase-id-token-999',
        'tenantId': 'tenant-abc',
      });
      expect(auth.revokeCalls, 0);
      expect(auth.revokeAccessTokenCalls, 0);
    });

    test('Web: retries transient HTTP 503 failure and succeeds on retry', () async {
      final auth = _TestFirebaseAuth();
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => _FakeUserCredential(
          credential: _FakeOAuthCredential(
            accessToken: 'web-apple-access-token-retry',
          ),
        ),
      );
      auth.user = user;
      var callIndex = 0;
      final fakeHttp = _FakeHttpClient((_) async {
        callIndex += 1;
        if (callIndex == 1) {
          return http.Response('Service Unavailable', 503);
        }
        return http.Response('{}', 200);
      });
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        isWeb: true,
        httpClient: fakeHttp,
        maxRevokeAttempts: 3,
        revokeRetryDelay: Duration.zero,
      );

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.success);
      expect(fakeHttp.requestCount, 2);
    });

    test('Web: returns failedNonBlocking when credential.accessToken is missing', () async {
      final auth = _TestFirebaseAuth();
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => _FakeUserCredential(
          additionalUserInfo: _FakeAdditionalUserInfo(authorizationCode: null),
          credential: _FakeOAuthCredential(accessToken: null),
        ),
      );
      auth.user = user;
      final fakeHttp = _FakeHttpClient((_) async => http.Response('{}', 200));
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        isWeb: true,
        httpClient: fakeHttp,
      );

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.failedNonBlocking);
      expect(fakeHttp.requestCount, 0);
    });

    test('retries on revocation timeout and exhausts cleanly to failedNonBlocking', () async {
      final auth = _TestFirebaseAuth();
      final user = _FakeUser(
        providerData: [_FakeUserInfo('apple.com')],
        reauthHandler: (_) async => _FakeUserCredential(
          additionalUserInfo: _FakeAdditionalUserInfo(
            authorizationCode: 'valid-code',
          ),
        ),
      );
      auth.user = user;
      auth.onRevokeWithCode = (code) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      };
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        targetPlatform: TargetPlatform.iOS,
        maxRevokeAttempts: 2,
        revokeRetryDelay: Duration.zero,
        revokeTimeout: const Duration(milliseconds: 10),
      );

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.failedNonBlocking);
      expect(auth.revokeCalls, 2);
    });
  });
}
