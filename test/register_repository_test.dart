import 'package:cherry_mvp/core/config/firestore_constants.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/services/firebase_auth_service.dart';
import 'package:cherry_mvp/core/services/firebase_storage.dart';
import 'package:cherry_mvp/core/services/firestore_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/register/register_model.dart';
import 'package:cherry_mvp/features/register/register_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFirebaseAuth implements FirebaseAuth {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected FirebaseAuth call: ${invocation.memberName}');
  }
}

class _FakeFirebaseFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError(
      'Unexpected FirebaseFirestore call: ${invocation.memberName}',
    );
  }
}

class _FakeFirebaseStorage implements FirebaseStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError(
      'Unexpected FirebaseStorage call: ${invocation.memberName}',
    );
  }
}

class _FakeAuthService extends FirebaseAuthService {
  _FakeAuthService({this.verificationResult}) : super(firebaseAuth: _FakeFirebaseAuth());

  final Result<void>? verificationResult;
  int signUpCalls = 0;
  int verificationEmailCalls = 0;

  @override
  Future<Result<UserCredentials>> signUp(String email, String password) async {
    signUpCalls += 1;
    return Result.success(UserCredentials(uid: 'user-123', email: email));
  }

  @override
  Future<Result<void>> sendVerificationEmail() async {
    verificationEmailCalls += 1;
    return verificationResult ?? Result.success(null);
  }
}

class _FakeFirestoreService extends FirestoreService {
  _FakeFirestoreService({
    required super.prefs,
  }) : super(
         firebaseFirestore: _FakeFirebaseFirestore(),
         firebaseAuth: _FakeFirebaseAuth(),
       );

  int saveDocumentCalls = 0;
  int fetchUserCalls = 0;
  Map<String, dynamic>? savedData;

  @override
  Future<Result<List<QueryDocumentSnapshot>>> queryCollection(
    String collectionPath, {
    required String field,
    required dynamic value,
  }) async {
    return Result.success(<QueryDocumentSnapshot>[]);
  }

  @override
  Future<Result<void>> saveDocument(
    String collectionName,
    String documentId,
    Map<String, dynamic> data, {
    bool isOrder = false,
  }) async {
    saveDocumentCalls += 1;
    savedData = data;
    return Result.success(null);
  }

  @override
  Future<Result<void>> fetchUser(String uid) async {
    fetchUserCalls += 1;
    return Result.success(null);
  }
}

RegisterRequest _request() {
  return RegisterRequest(
    firstname: 'Taylor',
    email: 'taylor@example.com',
    phone: '07123456789',
    username: 'taylor',
    password: 'password123',
    imageFile: null,
  );
}

void main() {
  late SharedPreferences prefs;
  late _FakeAuthService authService;
  late _FakeFirestoreService firestoreService;
  late RegisterRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    authService = _FakeAuthService();
    firestoreService = _FakeFirestoreService(prefs: prefs);
    repository = RegisterRepository(
      authService,
      firestoreService,
      StorageProvider(firebaseStorage: _FakeFirebaseStorage()),
    );
  });

  test('successful registration sends a verification email', () async {
    final result = await repository.register(_request());

    expect(result.isSuccess, isTrue);
    expect(authService.signUpCalls, 1);
    expect(firestoreService.saveDocumentCalls, 1);
    expect(firestoreService.fetchUserCalls, 1);
    expect(authService.verificationEmailCalls, 1);
    expect(
      firestoreService.savedData?[FirestoreConstants.email],
      'taylor@example.com',
    );
  });

  test('verification email failure does not fail account creation', () async {
    authService = _FakeAuthService(
      verificationResult: Result.failure('Unable to send verification email'),
    );
    repository = RegisterRepository(
      authService,
      firestoreService,
      StorageProvider(firebaseStorage: _FakeFirebaseStorage()),
    );

    final result = await repository.register(_request());

    expect(result.isSuccess, isTrue);
    expect(authService.verificationEmailCalls, 1);
  });
}
