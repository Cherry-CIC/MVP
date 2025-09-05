import 'package:cherry_mvp/core/config/firestore_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'error_string.dart';

class FirestoreService {
  final FirebaseFirestore firebaseFirestore;
  final SharedPreferences prefs;

  FirestoreService({
    required this.firebaseFirestore,
    required this.prefs,
  });

  Future<Result<DocumentSnapshot>> getDocument(
      String collectionName, String documentId,
      {bool isOrder = false}) async {
    try {
      dynamic documentSnapshot;
      if (isOrder) {
        final uid = prefs.getString(FirestoreConstants.id);
        documentSnapshot = await firebaseFirestore
            .collection(FirestoreConstants.pathUserCollection)
            .doc(uid)
            .collection(collectionName)
            .doc(documentId)
            .get();
      } else {
        documentSnapshot = await firebaseFirestore
            .collection(collectionName)
            .doc(documentId)
            .get();
      }

      if (documentSnapshot.exists) {
        return Result.success(documentSnapshot);
      } else {
        return Result.failure(ErrorStrings.documentError);
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> saveDocument(
      String collectionName, String documentId, Map<String, dynamic> data,
      {bool isOrder = false}) async {
    try {
      if (isOrder) {
        final uid = prefs.getString(FirestoreConstants.id);
        await firebaseFirestore
            .collection(FirestoreConstants.pathUserCollection)
            .doc(uid)
            .collection(collectionName)
            .doc(documentId)
            .set(data);
      } else {
        await firebaseFirestore
            .collection(collectionName)
            .doc(documentId)
            .set(data);
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Stream<Result<QuerySnapshot>> getRealTimeUpdates(String collectionName) {
    try {
      return firebaseFirestore.collection(collectionName).snapshots().map(
            (querySnapshot) => Result.success(querySnapshot),
          );
    } catch (e) {
      return Stream.value(Result.failure(e.toString()));
    }
  }
}
