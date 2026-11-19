import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/services/firebase_auth_service.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/unexpected_api_service.dart';

class _FakeLoginRepository implements LoginRepository {
  _FakeLoginRepository(
    this.logoutResult, {
    this.revokeAppleTokenResult = RevokeAppleTokenResult.skipped,
  });

  final Result<void> logoutResult;
  final RevokeAppleTokenResult revokeAppleTokenResult;
  int revokeAppleTokenCalls = 0;

  @override
  Future<Result<void>> logout() async => logoutResult;

  @override
  Future<RevokeAppleTokenResult> revokeAppleAccessIfLinked() async {
    revokeAppleTokenCalls += 1;
    return revokeAppleTokenResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected login call: ${invocation.memberName}');
  }
}

class _FakeFirebaseAuth implements FirebaseAuth {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected Firebase Auth call: ${invocation.memberName}');
  }
}

class _FakeFirebaseFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected Firestore call: ${invocation.memberName}');
  }
}

class _RecordingNavigationProvider extends NavigationProvider {
  int goBackCount = 0;
  String? removedUntilRoute;

  @override
  void goBack([Object? arguments]) {
    goBackCount += 1;
  }

  @override
  Future<dynamic> navigateToAndRemoveUntil(
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) async {
    removedUntilRoute = routeName;
  }
}

class _DeleteAccountApiService implements ApiService {
  int deleteCalls = 0;

  @override
  Future<Result<T>> delete<T>(String endpoint) async {
    deleteCalls += 1;
    return Result.success(<String, dynamic>{'success': true} as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected API request: ${invocation.memberName}');
  }
}

Product _product() {
  return Product(
    id: 'account-a-liked-product',
    name: 'Account A liked item',
    description: 'A liked test product',
    quality: 'Good',
    productImages: const [AppImages.product1],
    donation: 6,
    price: 7,
    securityFee: 1,
    likes: 0,
    number: 1,
    size: 'M',
    postageSizeId: 'small',
  );
}

ProductViewModel _productViewModel() {
  return ProductViewModel(
    productRepository: ProductRepository(const UnexpectedApiService()),
    navigator: NavigationProvider(),
  )..cacheLikedProducts([_product()]);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'account-a-preference': 'private value',
    });
  });

  testWidgets('successful logout clears account-scoped liked state', (
    tester,
  ) async {
    final loginRepository = _FakeLoginRepository(Result.success(null));
    final firebaseAuth = _FakeFirebaseAuth();
    final productViewModel = _productViewModel();
    final navigator = _RecordingNavigationProvider();

    final authViewModel = AuthViewModel(
      loginRepository: loginRepository,
      navigator: navigator,
      firebaseAuth: firebaseAuth,
      firestore: _FakeFirebaseFirestore(),
      apiService: const UnexpectedApiService(),
      clearUserState: productViewModel.clearUserState,
    );

    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await authViewModel.logout(context);

    expect(productViewModel.cachedLikedProducts, isEmpty);
    expect(
      productViewModel.isProductLiked('account-a-liked-product'),
      isFalse,
    );
    expect(
      (await SharedPreferences.getInstance()).get('account-a-preference'),
      isNull,
    );
    expect(navigator.goBackCount, 0);
    expect(navigator.removedUntilRoute, AppRoutes.welcome);
  });

  test('successful account deletion clears account-scoped liked state', () async {
    final loginRepository = _FakeLoginRepository(Result.success(null));
    final productViewModel = _productViewModel();
    final navigator = _RecordingNavigationProvider();

    final authViewModel = AuthViewModel(
      loginRepository: loginRepository,
      navigator: navigator,
      firebaseAuth: _FakeFirebaseAuth(),
      firestore: _FakeFirebaseFirestore(),
      apiService: _DeleteAccountApiService(),
      clearUserState: productViewModel.clearUserState,
    );

    final result = await authViewModel.deleteAccount();

    expect(result.isSuccess, isTrue);
    expect(productViewModel.cachedLikedProducts, isEmpty);
    expect(
      productViewModel.isProductLiked('account-a-liked-product'),
      isFalse,
    );
    expect(
      (await SharedPreferences.getInstance()).get('account-a-preference'),
      isNull,
    );
    expect(navigator.removedUntilRoute, AppRoutes.welcome);
  });

  group('Apple sign-in token revocation during account deletion (Issue #549)', () {
    test('Scenario: Account without Apple proceeds normally without Apple prompt', () async {
      final loginRepository = _FakeLoginRepository(
        Result.success(null),
        revokeAppleTokenResult: RevokeAppleTokenResult.skipped,
      );
      final apiService = _DeleteAccountApiService();
      final navigator = _RecordingNavigationProvider();
      final productViewModel = _productViewModel();

      final authViewModel = AuthViewModel(
        loginRepository: loginRepository,
        navigator: navigator,
        firebaseAuth: _FakeFirebaseAuth(),
        firestore: _FakeFirebaseFirestore(),
        apiService: apiService,
        clearUserState: productViewModel.clearUserState,
      );

      final result = await authViewModel.deleteAccount();

      expect(result.isSuccess, isTrue);
      expect(loginRepository.revokeAppleTokenCalls, 1);
      expect(apiService.deleteCalls, 1);
      expect(navigator.removedUntilRoute, AppRoutes.welcome);
    });

    test('Scenario: Account linked to Apple revokes token and proceeds to delete account', () async {
      final loginRepository = _FakeLoginRepository(
        Result.success(null),
        revokeAppleTokenResult: RevokeAppleTokenResult.success,
      );
      final apiService = _DeleteAccountApiService();
      final navigator = _RecordingNavigationProvider();
      final productViewModel = _productViewModel();

      final authViewModel = AuthViewModel(
        loginRepository: loginRepository,
        navigator: navigator,
        firebaseAuth: _FakeFirebaseAuth(),
        firestore: _FakeFirebaseFirestore(),
        apiService: apiService,
        clearUserState: productViewModel.clearUserState,
      );

      final result = await authViewModel.deleteAccount();

      expect(result.isSuccess, isTrue);
      expect(loginRepository.revokeAppleTokenCalls, 1);
      expect(apiService.deleteCalls, 1);
      expect(navigator.removedUntilRoute, AppRoutes.welcome);
    });

    test('Scenario: User cancels Apple re-authentication prompt - deletion is safely aborted', () async {
      final loginRepository = _FakeLoginRepository(
        Result.success(null),
        revokeAppleTokenResult: RevokeAppleTokenResult.userCancelled,
      );
      final apiService = _DeleteAccountApiService();
      final navigator = _RecordingNavigationProvider();
      final productViewModel = _productViewModel();

      final authViewModel = AuthViewModel(
        loginRepository: loginRepository,
        navigator: navigator,
        firebaseAuth: _FakeFirebaseAuth(),
        firestore: _FakeFirebaseFirestore(),
        apiService: apiService,
        clearUserState: productViewModel.clearUserState,
      );

      final result = await authViewModel.deleteAccount();

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Account deletion was cancelled.');
      expect(loginRepository.revokeAppleTokenCalls, 1);
      // Backend delete must NOT be called when cancelled!
      expect(apiService.deleteCalls, 0);
      expect(authViewModel.deleteAccountStatus.type, StatusType.uninitialized);
      expect(navigator.removedUntilRoute, isNull);
    });

    test('Scenario: Revocation fails technically - deletion proceeds without blocking', () async {
      final loginRepository = _FakeLoginRepository(
        Result.success(null),
        revokeAppleTokenResult: RevokeAppleTokenResult.failedNonBlocking,
      );
      final apiService = _DeleteAccountApiService();
      final navigator = _RecordingNavigationProvider();
      final productViewModel = _productViewModel();

      final authViewModel = AuthViewModel(
        loginRepository: loginRepository,
        navigator: navigator,
        firebaseAuth: _FakeFirebaseAuth(),
        firestore: _FakeFirebaseFirestore(),
        apiService: apiService,
        clearUserState: productViewModel.clearUserState,
      );

      final result = await authViewModel.deleteAccount();

      expect(result.isSuccess, isTrue);
      expect(loginRepository.revokeAppleTokenCalls, 1);
      // Backend deletion must still proceed!
      expect(apiService.deleteCalls, 1);
      expect(navigator.removedUntilRoute, AppRoutes.welcome);
    });
  });
}
