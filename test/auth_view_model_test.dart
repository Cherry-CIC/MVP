import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
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
  _FakeLoginRepository(this.logoutResult);

  final Result<void> logoutResult;

  @override
  Future<Result<void>> logout() async => logoutResult;

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
  @override
  Future<Result<T>> delete<T>(String endpoint) async {
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
    expect(navigator.goBackCount, 1);
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
}
