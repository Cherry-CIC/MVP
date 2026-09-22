import 'dart:async';

import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/login/login_viewmodel.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';
import 'package:cherry_mvp/features/welcome/widgets/auth_gate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/unexpected_api_service.dart';

class _PendingLoginRepository implements LoginRepository {
  final result = Completer<Result<void>>();
  int logoutCalls = 0;

  @override
  Future<Result<void>> logout() {
    logoutCalls += 1;
    return result.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected login call: ${invocation.memberName}');
  }
}

class _StreamingFirebaseAuth implements FirebaseAuth {
  final changes = StreamController<User?>.broadcast();

  @override
  User? get currentUser => null;

  @override
  Stream<User?> userChanges() async* {
    yield currentUser;
    yield* changes.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected Firebase Auth call: ${invocation.memberName}');
  }
}

class _UnusedFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected Firestore call: ${invocation.memberName}');
  }
}

class _PushObserver extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes += 1;
    super.didPush(route, previousRoute);
  }
}

class _LogoutHarness {
  static const authenticatedRoutes = [
    AppRoutes.home,
    '/profile',
    AppRoutes.settingspage,
  ];

  final repository = _PendingLoginRepository();
  final firebaseAuth = _StreamingFirebaseAuth();
  final navigator = NavigationProvider();
  final observer = _PushObserver();
  int clearUserStateCalls = 0;

  late final viewModel = AuthViewModel(
    loginRepository: repository,
    navigator: navigator,
    firebaseAuth: firebaseAuth,
    firestore: _UnusedFirestore(),
    apiService: const UnexpectedApiService(),
    clearUserState: () => clearUserStateCalls += 1,
  );

  Future<BuildContext> pumpStack(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FirebaseAuth>.value(value: firebaseAuth),
          Provider<NavigationProvider>.value(value: navigator),
          ChangeNotifierProvider(
            create: (_) => LoginViewModel(
              loginRepository: repository,
              navigator: navigator,
            ),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigator.navigatorKey,
          navigatorObservers: [observer],
          home: const AuthGate(),
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.welcome) {
              return AppRoutes.generateRoute(settings);
            }
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Scaffold(
                key: ValueKey(settings.name!),
                body: Text(settings.name!),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final route in authenticatedRoutes) {
      unawaited(navigator.navigateTo(route));
      await tester.pumpAndSettle();
    }
    for (final route in authenticatedRoutes) {
      expect(find.byKey(ValueKey(route), skipOffstage: false), findsOneWidget);
    }
    return tester.element(find.text(AppRoutes.settingspage));
  }

  void expectWelcomeRoot() {
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.byType(AuthGate, skipOffstage: false), findsOneWidget);
    expect(firebaseAuth.changes.hasListener, isTrue);
    for (final route in authenticatedRoutes) {
      expect(find.byKey(ValueKey(route), skipOffstage: false), findsNothing);
    }
    expect(navigator.navigatorKey.currentState!.canPop(), isFalse);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await firebaseAuth.changes.close();
    viewModel.dispose();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'private-preference': 'saved'});
  });

  testWidgets('logout completes on Welcome and removes every previous route', (
    tester,
  ) async {
    final harness = _LogoutHarness();
    final context = await harness.pumpStack(tester);
    var completed = false;
    unawaited(harness.viewModel.logout(context).then((_) => completed = true));

    harness.repository.result.complete(Result.success(null));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(harness.viewModel.status.type, StatusType.success);
    harness.expectWelcomeRoot();
    expect(await harness.navigator.navigatorKey.currentState!.maybePop(), isFalse);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    harness.expectWelcomeRoot();
    await harness.dispose(tester);
  });

  testWidgets('pending and repeated logout requests produce one reset', (
    tester,
  ) async {
    final harness = _LogoutHarness();
    final context = await harness.pumpStack(tester);
    final pushesBeforeLogout = harness.observer.pushes;
    unawaited(harness.viewModel.logout(context));
    unawaited(harness.viewModel.logout(context));
    await tester.pump();

    expect(harness.viewModel.status.type, StatusType.loading);
    expect(harness.repository.logoutCalls, 1);
    expect(harness.observer.pushes, pushesBeforeLogout);
    expect(find.text(AppRoutes.settingspage), findsOneWidget);
    expect(find.byType(WelcomePage), findsNothing);
    expect(harness.clearUserStateCalls, 0);

    harness.repository.result.complete(Result.success(null));
    await tester.pumpAndSettle();

    expect(harness.observer.pushes, pushesBeforeLogout + 1);
    expect(harness.clearUserStateCalls, 1);
    harness.expectWelcomeRoot();
    await harness.dispose(tester);
  });

  for (final throwsError in [false, true]) {
    testWidgets(
      '${throwsError ? 'thrown' : 'returned'} logout failure keeps the current routes',
      (tester) async {
        final harness = _LogoutHarness();
        final context = await harness.pumpStack(tester);
        final pushesBeforeLogout = harness.observer.pushes;
        unawaited(harness.viewModel.logout(context));
        if (throwsError) {
          harness.repository.result.completeError(StateError('Sign-out failed'));
        } else {
          harness.repository.result.complete(Result.failure('Sign-out failed'));
        }
        await tester.pumpAndSettle();

        expect(harness.viewModel.status.type, StatusType.failure);
        expect(harness.observer.pushes, pushesBeforeLogout);
        expect(find.text(AppRoutes.settingspage), findsOneWidget);
        expect(find.byType(WelcomePage), findsNothing);
        expect(find.textContaining('Sign-out failed'), findsOneWidget);
        for (final route in _LogoutHarness.authenticatedRoutes) {
          expect(find.byKey(ValueKey(route), skipOffstage: false), findsOneWidget);
        }
        expect(
          (await SharedPreferences.getInstance()).get('private-preference'),
          'saved',
        );
        await harness.dispose(tester);
      },
    );
  }

  testWidgets('logout resets after its context unmounts and auth emits null', (
    tester,
  ) async {
    final harness = _LogoutHarness();
    final context = await harness.pumpStack(tester);
    unawaited(harness.viewModel.logout(context));
    harness.navigator.goBack();
    await tester.pumpAndSettle();
    expect(context.mounted, isFalse);

    harness.firebaseAuth.changes.add(null);
    harness.repository.result.complete(Result.success(null));
    await tester.pumpAndSettle();

    expect(harness.viewModel.status.type, StatusType.success);
    harness.expectWelcomeRoot();
    expect(tester.takeException(), isNull);
    await harness.dispose(tester);
  });
}
