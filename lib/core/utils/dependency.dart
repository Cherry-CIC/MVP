import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/theme/theme_notifier.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';
import 'package:cherry_mvp/features/categories/category_repository.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_repository.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/features/discover/discover_viewmodel.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/donation/donation_view_model.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/login/login_viewmodel.dart';
import 'package:cherry_mvp/features/forgot_password/forgot_password_repository.dart';
import 'package:cherry_mvp/features/forgot_password/forgot_password_viewmodel.dart';
import 'package:cherry_mvp/features/orders/orders_repository.dart';
import 'package:cherry_mvp/features/orders/orders_view_model.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:cherry_mvp/features/products/delete_listing_view_model.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/safety_repository.dart';
import 'package:cherry_mvp/features/profile/edit_profile_repository.dart';
import 'package:cherry_mvp/features/profile/edit_profile_view_model.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_repository.dart';
import 'package:cherry_mvp/features/register/register_repository.dart';
import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/features/search/search_repository.dart';
import 'package:cherry_mvp/features/search/search_viewmodel.dart';

List<SingleChildWidget> buildProviders(SharedPreferences prefs) {
  // Configuration flag - reads from environment variable
  final bool useMockData = dotenv.env['USE_MOCK_DATA'] == 'true';
  return [
    Provider<FirebaseAuth>(create: (_) => FirebaseAuth.instance),
    Provider<FirebaseFirestore>(create: (_) => FirebaseFirestore.instance),
    Provider(create: (_) => NavigationProvider()),
    ChangeNotifierProvider(create: (_) => ThemeNotifier(prefs)),

    ChangeNotifierProvider(create: (_) => DeletedListings()),

    // Add API Service
    Provider<ApiService>(
      create: (context) => DioApiService(
        firebaseAuth: Provider.of<FirebaseAuth>(context, listen: false),
      ),
    ),

    Provider<FirebaseAuthService>(
      create: (context) => FirebaseAuthService(
        firebaseAuth: Provider.of<FirebaseAuth>(context, listen: false),
      ),
    ),
    Provider<FirestoreService>(
      create: (context) => FirestoreService(
        firebaseFirestore: Provider.of<FirebaseFirestore>(
          context,
          listen: false,
        ),
        prefs: prefs,
        firebaseAuth: FirebaseAuth.instance,
      ),
    ),
    Provider<StorageProvider>(
      create: (_) => StorageProvider(firebaseStorage: FirebaseStorage.instance),
    ),
    Provider<LoginRepository>(
      create: (context) => LoginRepository(
        Provider.of<FirebaseAuthService>(context, listen: false),
        Provider.of<FirestoreService>(context, listen: false),
      ),
    ),
    Provider<ForgotPasswordRepository>(
      create: (context) => ForgotPasswordRepository(
        Provider.of<FirebaseAuthService>(context, listen: false),
      ),
    ),
    Provider<RegisterRepository>(
      create: (context) => RegisterRepository(
        Provider.of<FirebaseAuthService>(context, listen: false),
        Provider.of<FirestoreService>(context, listen: false),
        Provider.of<StorageProvider>(context, listen: false),
      ),
    ),

    ChangeNotifierProvider(create: (_) => SearchController()),
    Provider<IHomeRepository>(
      create: (context) {
        final firebaseAuth = Provider.of<FirebaseAuth>(context, listen: false);
        if (useMockData) {
          return HomeRepositoryMock(
            currentUserIdProvider: () => firebaseAuth.currentUser?.uid,
          );
        } else {
          return HomeRepository(
            Provider.of<ApiService>(context, listen: false),
            currentUserIdProvider: () => firebaseAuth.currentUser?.uid,
          );
        }
      },
    ),
    Provider<DiscoverRepository>(create: (context) => DiscoverRepository()),
    Provider<ProductRepository>(
      create: (context) => ProductRepository(
        context.read<ApiService>(),
        deletedListings: context.read<DeletedListings>(),
      ),
    ),
    Provider<IEditListingRepository>(
      create: (context) => EditListingRepository(
        apiService: context.read<ApiService>(),
        productRepository: context.read<ProductRepository>(),
        storageProvider: context.read<StorageProvider>(),
        currentUserId: () => context.read<FirebaseAuth>().currentUser?.uid,
      ),
    ),
    Provider<SafetyRepository>(
      create: (context) => SafetyRepository(
        Provider.of<ApiService>(context, listen: false),
      ),
    ),
    Provider<IDonationRepository>(
      create: (context) {
        if (useMockData) {
          return MockDonationRepository();
        } else {
          return DonationRepository(
            apiService: Provider.of<ApiService>(context, listen: false),
            storageProvider: Provider.of<StorageProvider>(
              context,
              listen: false,
            ),
            firebaseAuth: Provider.of<FirebaseAuth>(context, listen: false),
          );
        }
      },
    ),
    Provider<ICategoryRepository>(
      create: (context) {
        return CategoryRepository(
          Provider.of<ApiService>(context, listen: false),
        );
      },
    ),
    Provider<ICheckoutRepository>(
      create: (context) {
        return CheckoutRepository(
          Provider.of<ApiService>(context, listen: false),
        );
      },
    ),
    Provider<IOrdersRepository>(
      create: (context) => OrdersRepository(Provider.of<ApiService>(context, listen: false)),
    ),
    Provider<IProfileListingsRepository>(
      create: (context) => ProfileListingsRepository(
        Provider.of<ApiService>(context, listen: false),
      ),
    ),
    Provider<IPublicUserProfileRepository>(
      create: (context) => PublicUserProfileRepository(
        Provider.of<ApiService>(context, listen: false),
      ),
    ),
    Provider<IEditProfileRepository>(
      create: (context) => EditProfileRepository(
        Provider.of<ApiService>(context, listen: false),
      ),
    ),
    Provider<ICharityRepository>(
      create: (context) {
        if (useMockData) {
          return CharityRepositoryMock();
        } else {
          return CharityRepository(
            Provider.of<ApiService>(context, listen: false),
          );
        }
      },
    ),
    ChangeNotifierProvider<LoginViewModel>(
      create: (context) => LoginViewModel(
        loginRepository: Provider.of<LoginRepository>(context, listen: false),
        navigator: Provider.of<NavigationProvider>(context, listen: false),
      ),
    ),
    ChangeNotifierProvider<ForgotPasswordViewModel>(
      create: (context) => ForgotPasswordViewModel(
        forgotPasswordRepository: Provider.of<ForgotPasswordRepository>(
          context,
          listen: false,
        ),
        navigator: Provider.of<NavigationProvider>(context, listen: false),
      ),
    ),
    ChangeNotifierProvider<RegisterViewModel>(
      create: (context) => RegisterViewModel(
        registerRepository: Provider.of<RegisterRepository>(
          context,
          listen: false,
        ),
        navigator: Provider.of<NavigationProvider>(context, listen: false),
      ),
    ),
    ChangeNotifierProvider<ProductViewModel>(
      create: (context) => ProductViewModel(
        deletedListings: context.read<DeletedListings>(),
        productRepository: Provider.of<ProductRepository>(
          context,
          listen: false,
        ),
        safetyRepository: Provider.of<SafetyRepository>(
          context,
          listen: false,
        ),
        navigator: Provider.of<NavigationProvider>(context, listen: false),
        currentUserIdProvider: () => Provider.of<FirebaseAuth>(context, listen: false).currentUser?.uid,
      ),
    ),
    ChangeNotifierProvider<HomeViewModel>(
      create: (context) {
        final productViewModel = Provider.of<ProductViewModel>(
          context,
          listen: false,
        );
        return HomeViewModel(
          deletedListings: context.read<DeletedListings>(),
          homeRepository: Provider.of<IHomeRepository>(context, listen: false),
          onProductsLoaded: productViewModel.reconcileProductCounts,
        );
      },
    ),
    Provider<SearchRepository>(create: (context) => SearchRepository()),
    ChangeNotifierProvider<SearchViewModel>(
      create: (context) => SearchViewModel(
        searchRepository: Provider.of<SearchRepository>(context, listen: false),
      ),
    ),
    ChangeNotifierProvider<DiscoverViewModel>(
      create: (context) => DiscoverViewModel(
        discoverRepository: Provider.of<DiscoverRepository>(
          context,
          listen: false,
        ),
      ),
    ),
    ChangeNotifierProvider<DonationViewModel>(
      create: (context) => DonationViewModel(
        donationRepository: Provider.of<IDonationRepository>(
          context,
          listen: false,
        ),
        navigator: Provider.of<NavigationProvider>(context, listen: false),
      ),
    ),
    ChangeNotifierProvider<CategoryViewModel>(
      create: (context) => CategoryViewModel(
        categoryRepository: Provider.of<ICategoryRepository>(
          context,
          listen: false,
        ),
        navigator: Provider.of<NavigationProvider>(context, listen: false),
      ),
    ),

    ChangeNotifierProvider<CheckoutViewModel>(
      create: (context) => CheckoutViewModel(
        checkoutRepository: Provider.of<ICheckoutRepository>(
          context,
          listen: false,
        ),
        navigator: Provider.of<NavigationProvider>(context, listen: false),
        donationRepository: Provider.of<IDonationRepository>(
          context,
          listen: false,
        ),
        currentUserIdProvider: () => Provider.of<FirebaseAuth>(context, listen: false).currentUser?.uid,
      ),
    ),
    ChangeNotifierProvider<CharityViewModel>(
      create: (context) => CharityViewModel(
        charityRepository: Provider.of<ICharityRepository>(
          context,
          listen: false,
        ),
        navigator: Provider.of<NavigationProvider>(context, listen: false),
      ),
    ),
    ChangeNotifierProvider<OrdersViewModel>(
      create: (context) => OrdersViewModel(
        repository: Provider.of<IOrdersRepository>(context, listen: false),
      ),
    ),
    ChangeNotifierProvider<ProfileListingsViewModel>(
      create: (context) => ProfileListingsViewModel(
        deletedListings: context.read<DeletedListings>(),
        currentUserIdProvider: () => context.read<FirebaseAuth>().currentUser?.uid,
        repository: Provider.of<IProfileListingsRepository>(
          context,
          listen: false,
        ),
      ),
    ),
    ChangeNotifierProvider<DeleteListingViewModel>(
      lazy: false,
      create: (context) {
        final auth = context.read<FirebaseAuth>();
        final profile = context.read<ProfileListingsViewModel>();
        final products = context.read<ProductViewModel>();
        return DeleteListingViewModel(
          repository: context.read<ProductRepository>(),
          deletedListings: context.read<DeletedListings>(),
          currentUserId: () => auth.currentUser?.uid,
          accountChanges: auth.authStateChanges().map((user) => user?.uid).distinct(),
          onAccountChanged: () {
            // Invalidate even if the user switched away and back before this
            // notification: those earlier requests still belong to an old session.
            profile.clearListings();
            profile.updateCurrentAccount();
            products.clearUserState();
            if (auth.currentUser != null) unawaited(profile.loadInitialListings());
          },
        );
      },
    ),
    ChangeNotifierProvider<EditProfileViewModel>(
      create: (context) => EditProfileViewModel(
        repository: Provider.of<IEditProfileRepository>(context, listen: false),
      ),
    ),
    // Logout provider
    ChangeNotifierProvider<AuthViewModel>(
      create: (context) => AuthViewModel(
        loginRepository: Provider.of<LoginRepository>(context, listen: false),
        navigator: Provider.of<NavigationProvider>(context, listen: false),
        firebaseAuth: Provider.of<FirebaseAuth>(context, listen: false),
        firestore: Provider.of<FirebaseFirestore>(context, listen: false),
        apiService: Provider.of<ApiService>(context, listen: false),
        clearUserState: Provider.of<ProductViewModel>(
          context,
          listen: false,
        ).clearUserState,
      ),
    ),
  ];
}
