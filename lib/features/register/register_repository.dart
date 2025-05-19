import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'register_model.dart';

class RegisterRepository {
  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService;

  RegisterRepository(this._authService, this._firestoreService);

  Future<Result<UserCredentials?>> register(RegisterRequest request) async {
    final result = await _authService.signUp(request.email, request.password);

    ///this code needs to be modified
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