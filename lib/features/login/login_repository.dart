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

  Future<Result<void>> fetchUserFromFirestore(String uid) async {
    // Fetch user document from Firestore
    final result = await _firestoreService.getDocument(FirestoreConstants.pathUserCollection, uid);

    if (result.isSuccess) {
      final document = result.value;
        // Store user data to shared preferences
        await _firestoreService.prefs.setString(FirestoreConstants.id, uid);
        await _firestoreService.prefs.setString(FirestoreConstants.firstname, document?.get(FirestoreConstants.firstname));
        await _firestoreService.prefs.setString(FirestoreConstants.photoUrl, document?.get(FirestoreConstants.photoUrl) ?? "");
        await _firestoreService.prefs.setString(FirestoreConstants.email, document?.get(FirestoreConstants.email) ?? "");

        return Result.success(null);
      } else {
      return Result.failure(result.error);
    }
  }
}