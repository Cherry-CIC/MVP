import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cherry_mvp/features/register/register_repository.dart';
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
      ),
    ),
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
      create: (context) => HomeViewModel(),
    ),
  ];
}
