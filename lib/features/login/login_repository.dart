import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'login_model.dart';

class LoginRepository {
  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService;

  LoginRepository(this._authService, this._firestoreService);

  Future<Result<UserCredentials?>> login(LoginRequest request) async {
    // Attempt to login using the auth service
    final result = await _authService.login(request.email, request.password);

    if (result.isSuccess) {
      // If login is successful, proceed to fetch user details
      final userCredentials = result.value;
      await fetchUserFromFirestore(userCredentials?.uid ?? "");
      return result;
    } else {
      return Result.failure(result.error);
    }
  }

  Future<Result<UserCredentials?>> signInWithGoogle() async {
    // Attempt to login with google using the auth service
    final result = await _authService.signInWithGoogle();
    if (result.isSuccess) {
      final userCredentials = result.value;
      // If login is successful,save user data into firestore
      // any change in google profile will be updated automatically like pic and name
      Map<String, dynamic> data = {
        FirestoreConstants.firstname: userCredentials?.firstname ?? "",
        FirestoreConstants.email: userCredentials?.email ?? "",
        FirestoreConstants.phone: userCredentials?.phonenumber ?? "",
        FirestoreConstants.id: userCredentials?.uid ?? "",
        FirestoreConstants.photoUrl: userCredentials?.photoUrl ?? "",
      };
      await _firestoreService.saveDocument(
        FirestoreConstants.pathUserCollection,
        userCredentials?.uid ?? "",
        data,
      );

      //proceed to fetch user details

      await fetchUserFromFirestore(userCredentials?.uid ?? "");

      return result;
    } else {
      return Result.failure(result.error);
    }
  }

  Future<Result<UserCredentials?>> signInWithApple() async {
    // Attempt to login with google using the auth service
    final result = await _authService.signInWithApple();

    if (result.isSuccess) {
      final userCredentials = result.value;
      // If login is successful,save user data into firestore
      // any change in google profile will be updated automatically like pic and name
      Map<String, dynamic> data = {
        FirestoreConstants.firstname: userCredentials?.firstname ?? "",
        FirestoreConstants.email: userCredentials?.email ?? "",
        FirestoreConstants.phone: userCredentials?.phonenumber ?? "",
        FirestoreConstants.id: userCredentials?.uid ?? "",
        FirestoreConstants.photoUrl: userCredentials?.photoUrl ?? "",
      };
      await _firestoreService.saveDocument(
        FirestoreConstants.pathUserCollection,
        userCredentials?.uid ?? "",
        data,
      );

      //proceed to fetch user details

      await fetchUserFromFirestore(userCredentials?.uid ?? "");

      return result;
    } else {
      return Result.failure(result.error);
    }
  }

  Future<Result<void>> fetchUserFromFirestore(String uid) async {
    // Fetch user document from Firestore
    final result = await _firestoreService.getDocument(
      FirestoreConstants.pathUserCollection,
      uid,
    );

    if (result.isSuccess) {
      final document = result.value;
      // Store user data to shared preferences
      await _firestoreService.prefs.setString(FirestoreConstants.id, uid);
      await _firestoreService.prefs.setString(
        FirestoreConstants.firstname,
        document?.get(FirestoreConstants.firstname),
      );
      await _firestoreService.prefs.setString(
        FirestoreConstants.photoUrl,
        document?.get(FirestoreConstants.photoUrl) ?? "",
      );
      await _firestoreService.prefs.setString(
        FirestoreConstants.email,
        document?.get(FirestoreConstants.email) ?? "",
      );

      return Result.success(null);
    } else {
      return Result.failure(result.error);
    }
  }

  Future<Result<void>> logout() async {
    return await _authService.logout();
  }
}
