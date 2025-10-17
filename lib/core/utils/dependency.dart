import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/services/services.dart';
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
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/register/register_repository.dart';
import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/features/search/search_repository.dart';
import 'package:cherry_mvp/features/search/search_viewmodel.dart';
import 'package:cherry_mvp/features/settings/setings_view_model.dart';
import 'package:cherry_mvp/features/settings/settings_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> buildProviders(prefs) {
  // Configuration flag - reads from environment variable
  // final bool useMockData = true;
  final bool useMockData = dotenv.env['USE_MOCK_DATA'] == 'true';
  return [
    Provider(create: (_) => NavigationProvider()),

    // Add API Service
    Provider<ApiService>(
      create: (_) => DioApiService(firebaseAuth: FirebaseAuth.instance),
    ),

    Provider<FirebaseAuthService>(
      create: (_) => FirebaseAuthService(firebaseAuth: FirebaseAuth.instance),
    ),
    Provider<FirestoreService>(
      create: (_) => FirestoreService(
        firebaseFirestore: FirebaseFirestore.instance,
        prefs: prefs,
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
    Provider<SettingsRepository>(
      create: (context) => SettingsRepository(
        Provider.of<FirestoreService>(context, listen: false),
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
        if (useMockData) {
          return HomeRepositoryMock();
        } else {
          return HomeRepository(
            Provider.of<ApiService>(context, listen: false),
          );
        }
      },
    ),
    Provider<DiscoverRepository>(create: (context) => DiscoverRepository()),
    Provider<ProductRepository>(create: (context) => ProductRepository()),
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
            firebaseAuth: FirebaseAuth.instance,
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
          Provider.of<FirestoreService>(context, listen: false),
        );
      },
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
    ChangeNotifierProvider<SettingsViewModel>(
      create: (context) => SettingsViewModel(
        settingsRepository: Provider.of<SettingsRepository>(
          context,
          listen: false,
        ),
      ),
    ),
    ChangeNotifierProvider<LoginViewModel>(
      create: (context) => LoginViewModel(
        loginRepository: Provider.of<LoginRepository>(context, listen: false),
      ),
    ),
    ChangeNotifierProvider<RegisterViewModel>(
      create: (context) => RegisterViewModel(
        registerRepository: Provider.of<RegisterRepository>(
          context,
          listen: false,
        ),
      ),
    ),

    ChangeNotifierProvider<HomeViewModel>(
      create: (context) => HomeViewModel(
        homeRepository: Provider.of<IHomeRepository>(context, listen: false),
      ),
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
    ChangeNotifierProvider<ProductViewModel>(
      create: (context) => ProductViewModel(
        productRepository: Provider.of<ProductRepository>(
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
      ),
    ),
    ChangeNotifierProvider<CategoryViewModel>(
      create: (context) => CategoryViewModel(
        categoryRepository: Provider.of<ICategoryRepository>(
          context,
          listen: false,
        ),
      ),
    ),

    ChangeNotifierProvider<CheckoutViewModel>(
      create: (context) => CheckoutViewModel(
        checkoutRepository: Provider.of<ICheckoutRepository>(
          context,
          listen: false,
        ),
      ),
    ),
    ChangeNotifierProvider<CharityViewModel>(
      create: (context) => CharityViewModel(
        charityRepository: Provider.of<ICharityRepository>(
          context,
          listen: false,
        ),
      ),
    ),
  ];
}
