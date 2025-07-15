import 'package:cherry_mvp/features/categories/category_repositoy.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/features/discover/discover_viewmodel.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/donation/donation_viewmodel.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/search/search_repository.dart';
import 'package:cherry_mvp/features/search/search_viewmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/register/register_repository.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/login/login_viewmodel.dart';
import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<SingleChildWidget> buildProviders(SharedPreferences prefs) {
  return [
    Provider(create: (_) => NavigationProvider()),
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
      create: (_) => StorageProvider(
        firebaseStorage: FirebaseStorage.instance,
      ),
    ),
    Provider<LoginRepository>(
      create: (context) => LoginRepository(
        Provider.of<FirebaseAuthService>(context, listen: false),
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
    Provider(create: (context) => HomeRepository()),
    Provider(create: (context) => DiscoverRepository()),
    Provider(create: (context) => ProductRepository()),
    Provider(create: (context) => DonationRepository()),
    Provider(create: (context) => SearchRepository()),
    Provider(create: (context) => CategoryRepositoy()),
    ChangeNotifierProvider(create: (_) => SearchController()),
    ChangeNotifierProvider<LoginViewModel>(
      create: (context) => LoginViewModel(
        loginRepository: Provider.of<LoginRepository>(context, listen: false),
      ),
    ),
    ChangeNotifierProvider<RegisterViewModel>(
      create: (context) => RegisterViewModel(
        registerRepository:
            Provider.of<RegisterRepository>(context, listen: false),
      ),
    ),
    ChangeNotifierProvider<HomeViewModel>(
        create: (context) => HomeViewModel(
              homeRepository:
                  Provider.of<HomeRepository>(context, listen: false),
            )),
    Provider<SearchRepository>(
      create: (context) => SearchRepository(),
    ),
    ChangeNotifierProvider<SearchViewModel>(
        create: (context) => SearchViewModel(
              searchRepository:
                  Provider.of<SearchRepository>(context, listen: false),
            )),
    ChangeNotifierProvider<DiscoverViewModel>(
        create: (context) => DiscoverViewModel(
              discoverRepository:
                  Provider.of<DiscoverRepository>(context, listen: false),
            )),
    ChangeNotifierProvider<ProductViewModel>(
        create: (context) => ProductViewModel(
              productRepository:
                  Provider.of<ProductRepository>(context, listen: false),
            )),
    ChangeNotifierProvider<DonationViewModel>(
      create: (context) => DonationViewModel(
        donationRepository:
            Provider.of<DonationRepository>(context, listen: false),
      ),
    ),
  ];
}
