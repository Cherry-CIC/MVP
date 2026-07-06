import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/login/login_model.dart';

enum SocialLoginType { google, apple }

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
      await _firestoreService.fetchUser(userCredentials?.uid ?? "");
      return result;
    } else {
      return Result.failure(result.error);
    }
  }

  Future<Result<UserCredentials?>> signInWithSocial(SocialLoginType type) async {
    // Attempt to login using the auth service
    final result = await switch (type) {
      SocialLoginType.google => _authService.signInWithGoogle(),
      SocialLoginType.apple => _authService.signInWithApple(),
    };

    if (result.isSuccess) {
      final userCredentials = result.value;
      final uId = userCredentials?.uid ?? "";

      final existingUserResult = await _firestoreService.getDocument(
        FirestoreConstants.pathUserCollection,
        uId,
      );
      final existingData = existingUserResult.isSuccess
          ? ((existingUserResult.value?.data() as Map<String, dynamic>?) ?? const <String, dynamic>{})
          : const <String, dynamic>{};

      final firstName = _getExistingOrCredential(
        existingData,
        FirestoreConstants.firstname,
        userCredentials?.firstname,
      );
      final email = _getExistingOrCredential(
        existingData,
        FirestoreConstants.email,
        userCredentials?.email,
      );
      final phone = _getExistingOrCredential(
        existingData,
        FirestoreConstants.phone,
        userCredentials?.phoneNumber,
      );
      final photoUrl = _getExistingOrCredential(
        existingData,
        FirestoreConstants.photoUrl,
        userCredentials?.photoUrl,
      );

      // If login is successful,save user data into firestore
      // any change in google profile will be updated automatically like pic and name

      Map<String, dynamic> data = {
        FirestoreConstants.firstname: firstName,
        FirestoreConstants.email: email,
        FirestoreConstants.phone: phone,
        FirestoreConstants.id: uId,
        FirestoreConstants.photoUrl: photoUrl,
      };
      await _firestoreService.firebaseFirestore
          .collection(FirestoreConstants.pathUserCollection)
          .doc(uId)
          .set(data, SetOptions(merge: true));

      //proceed to fetch user details
      await _firestoreService.fetchUser(uId);

      return result;
    } else {
      return Result.failure(result.error);
    }
  }

  String _getExistingOrCredential(
    Map<String, dynamic> existingData,
    String key,
    String? credentialValue,
  ) {
    final storedValue = existingData[key];
    return (storedValue is String && storedValue.isNotEmpty) ? storedValue : (credentialValue ?? "");
  }

  Future<Result<void>> logout() async {
    return await _authService.logout();
  }
}
