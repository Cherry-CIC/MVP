import 'package:cherry_mvp/core/models/user.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/login/login_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

const providerPhoto = 'https://example.org/provider.jpg';

class _Auth extends Fake implements FirebaseAuthService {
  @override
  Future<Result<UserCredentials>> signInWithGoogle() async =>
      Result.success(UserCredentials(uid: 'uid', email: null, photoUrl: providerPhoto));
}

class _Document extends Fake implements DocumentReference<Map<String, dynamic>> {
  late Map<String, dynamic> merged;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    expect(options?.merge, true);
    merged = data;
  }
}

class _Collection extends Fake implements CollectionReference<Map<String, dynamic>> {
  final document = _Document();

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => document;
}

class _Database extends Fake implements FirebaseFirestore {
  final users = _Collection();

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) => users;
}

class _Store extends Fake implements FirestoreService {
  _Store(this.lookup);

  final Result<DocumentSnapshot> lookup;
  @override
  final _Database firebaseFirestore = _Database();

  @override
  Future<Result<DocumentSnapshot>> getDocument(
    String collectionName,
    String documentId, {
    bool isOrder = false,
  }) async => lookup;

  @override
  Future<Result<void>> fetchUser(String uid) async => Result.success(null);
}

class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.fields);
  final Map<String, dynamic> fields;

  @override
  Map<String, dynamic> data() => fields;
}

void main() {
  Future<Map<String, dynamic>> signIn(Result<DocumentSnapshot> lookup) async {
    final store = _Store(lookup);
    final result = await LoginRepository(_Auth(), store).signInWithSocial(SocialLoginType.google);
    expect(result.isSuccess, true);
    return store.firebaseFirestore.users.document.merged;
  }

  test('seeds the provider photo on confirmed absence or an empty profile', () async {
    expect((await signIn(Result.failure(ErrorStrings.documentError)))['photoUrl'], providerPhoto);
    expect((await signIn(Result.success(_Snapshot({}))))['photoUrl'], providerPhoto);
  });

  test('omits the photo on a lookup error or when a saved photo exists', () async {
    expect(await signIn(Result.failure('unavailable')), isNot(contains('photoUrl')));
    expect(await signIn(Result.success(_Snapshot({'photoUrl': 'saved'}))), isNot(contains('photoUrl')));
  });
}
