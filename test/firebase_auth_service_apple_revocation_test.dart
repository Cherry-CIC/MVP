import 'package:cherry_mvp/core/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

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

class _FakeUserCredential implements UserCredential {
  @override
  final AdditionalUserInfo? additionalUserInfo;

  _FakeUserCredential({this.additionalUserInfo});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  @override
  final List<UserInfo> providerData;

  final Future<UserCredential> Function(AuthProvider provider)? reauthHandler;

  _FakeUser({required this.providerData, this.reauthHandler});

  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) {
    if (reauthHandler != null) {
      return reauthHandler!(provider);
    }
    throw StateError('reauthHandler not configured');
  }

  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) {
    if (reauthHandler != null) {
      return reauthHandler!(provider);
    }
    throw StateError('reauthHandler not configured');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestFirebaseAuth implements FirebaseAuth {
  _FakeUser? user;
  int revokeCalls = 0;
  String? lastRevokedCode;
  Exception? revokeError;

  _TestFirebaseAuth({this.user});

  @override
  User? get currentUser => user;

  @override
  Future<void> revokeTokenWithAuthorizationCode(String authorizationCode) async {
    revokeCalls += 1;
    lastRevokedCode = authorizationCode;
    if (revokeError != null) {
      throw revokeError!;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
      final service = FirebaseAuthService(firebaseAuth: auth);

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
      final service = FirebaseAuthService(firebaseAuth: auth);

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
      final service = FirebaseAuthService(firebaseAuth: auth);

      final result = await service.revokeAppleAccessIfLinked();

      expect(result, RevokeAppleTokenResult.failedNonBlocking);
      expect(auth.revokeCalls, 1);
    });
  });
}
