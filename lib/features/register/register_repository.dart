import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'register_model.dart';

class RegisterRepository {
  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService;
  final StorageProvider _storage;

  RegisterRepository(this._authService, this._firestoreService, this._storage);

  Future<Result<UserCredentials?>> register(RegisterRequest request) async {
    final usernameTaken = await _isUsernameTaken(request.username);
    if (usernameTaken) {
      return Result.failure("Username is already taken.");
    }

    final result = await _authService.signUp(request.email, request.password);

    if (result.isSuccess) {
      // If registration is successful, proceed with uploading user image and saving data
      final userCredentials = result.value;

      String? photoUrl;
      if (request.imageFile != null && request.imageFile!.existsSync()) {
        // Upload image if a file is provided
        final imageUploadResult = await _storage.uploadImage(
          request.imageFile!,
          'user_images/${request.firstname}_profile_picture.png',
        );

        if (imageUploadResult.isSuccess) {
          photoUrl = imageUploadResult
              .value; // Get the download URL of the uploaded image
        } else {
          return Result.failure(
            "Error uploading image: ${imageUploadResult.error}",
          );
        }
      }

      // Now, create the user in Firestore
      final firestoreResult = await createUserInFirestore(
        userCredentials?.uid ?? "",
        request.username,
        request.firstname,
        request.email,
        request.phone,
        photoUrl ?? "", // Pass the photo URL if available
      );

      if (firestoreResult.isSuccess) {
        return Result.success(userCredentials);
      } else {
        return Result.failure(firestoreResult.error);
      }
    } else {
      return Result.failure(result.error);
    }
  }

  //Send Verifcation Email

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
        FirestoreConstants.username,
        document?.get(FirestoreConstants.username),
      );
      await _firestoreService.prefs.setString(
        FirestoreConstants.firstname,
        document?.get(FirestoreConstants.firstname),
      );
      await _firestoreService.prefs.setString(
        FirestoreConstants.photoUrl,
        document?.get(FirestoreConstants.photoUrl) ?? "",
      );
      await _firestoreService.prefs.setString(
        FirestoreConstants.phone,
        document?.get(FirestoreConstants.phone) ?? "",
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

  Future<bool> _isUsernameTaken(String username) async {
    final result = await _firestoreService.queryCollection(
      FirestoreConstants.pathUserCollection,
      field: FirestoreConstants.username,
      value: username,
    );

    return result.isSuccess && result.value!.isNotEmpty;
  }

  Future<Result<void>> createUserInFirestore(
    String uid,
    String username,
    String firstName,
    String email,
    String phone,
    String photo,
  ) async {
    // Create user document in Firestore
    // Prepare the data to be saved
    Map<String, dynamic> data = {
      FirestoreConstants.username: username,
      FirestoreConstants.firstname: firstName,
      FirestoreConstants.email: email,
      FirestoreConstants.phone: phone,
      FirestoreConstants.id: uid,
      FirestoreConstants.photoUrl: photo,
    };

    final result = await _firestoreService.saveDocument(
      FirestoreConstants.pathUserCollection,
      uid,
      data,
    );

    if (result.isSuccess) {
      await fetchUserFromFirestore(uid);
      await _authService.sendVerificationEmail();
      return Result.success(null);
    } else {
      return Result.failure(result.error);
    }
  }
}
