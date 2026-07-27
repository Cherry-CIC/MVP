import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';
import 'package:cherry_mvp/features/home/home_page.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/orders_repository.dart';
import 'package:cherry_mvp/features/orders/orders_view_model.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/profile/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class _HomeRepositoryStub implements IHomeRepository {
  @override
  Future<Result<ProductPage>> fetchProducts({
    int limit = 20,
    String? cursor,
    String? search,
  }) async {
    return Result.success(
      const ProductPage(
        products: <Product>[],
        limit: 20,
        nextCursor: null,
        hasMore: false,
      ),
    );
  }
}

class _OrdersRepositoryStub implements IOrdersRepository {
  @override
  Future<Result<List<OrderSummary>>> fetchOrders() async {
    return Result.success(const []);
  }
}

class _ApiServiceMock extends Mock implements ApiService {}

class _FirebaseAuthMock extends Mock implements FirebaseAuth {}

class _FirebaseFirestoreMock extends Mock implements FirebaseFirestore {}

class _LoginRepositoryMock extends Mock implements LoginRepository {}

Future<void> _pumpHomePage(WidgetTester tester) async {
  final navigator = NavigationProvider();
  final firebaseAuth = _FirebaseAuthMock();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<NavigationProvider>.value(value: navigator),
        ChangeNotifierProvider(create: (_) => SearchController()),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(homeRepository: _HomeRepositoryStub()),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductViewModel(
            productRepository: ProductRepository(_ApiServiceMock()),
            navigator: navigator,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OrdersViewModel(repository: _OrdersRepositoryStub()),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            loginRepository: _LoginRepositoryMock(),
            navigator: navigator,
            firebaseAuth: firebaseAuth,
            firestore: _FirebaseFirestoreMock(),
            apiService: _ApiServiceMock(),
          ),
        ),
      ],
      child: const MaterialApp(home: HomePage()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openOrders(WidgetTester tester) async {
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Orders'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('My Orders retains one bottom bar with Profile selected', (
    tester,
  ) async {
    await _pumpHomePage(tester);
    await _openOrders(tester);

    expect(find.text('My Orders'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      2,
    );
  });

  testWidgets('visual and system back return My Orders to Profile', (
    tester,
  ) async {
    await _pumpHomePage(tester);
    await _openOrders(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsNothing);
    expect(find.text('Profile'), findsWidgets);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('My Orders'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsNothing);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('leaving or re-tapping Profile resets My Orders', (tester) async {
    await _pumpHomePage(tester);
    await _openOrders(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('My Orders'), findsNothing);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsNothing);
    expect(find.text('Orders'), findsOneWidget);
  });

  testWidgets('Profile remains mounted while My Orders is visible', (
    tester,
  ) async {
    await _pumpHomePage(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    final profileFinder = find.byType(ProfilePage, skipOffstage: false);
    final originalState = tester.state(profileFinder);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsOneWidget);
    expect(tester.state(profileFinder), same(originalState));
  });

  testWidgets('swiping away from Profile resets My Orders', (tester) async {
    await _pumpHomePage(tester);
    await _openOrders(tester);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsNothing);
    expect(find.text('Orders'), findsOneWidget);
  });
}
