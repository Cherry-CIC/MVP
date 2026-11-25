// ignore_for_file: subtype_of_sealed_class

import 'dart:io';
import 'dart:typed_data';

import 'package:cherry_mvp/core/models/profile_photo.dart';
import 'package:cherry_mvp/core/models/user.dart';
import 'package:cherry_mvp/core/services/firebase_storage.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/profile/edit_profile_repository.dart';
import 'package:cherry_mvp/features/profile/edit_profile_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/mockito.dart';

import 'support/unexpected_api_service.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'owner';
}

class _Auth extends Mock implements FirebaseAuth {
  @override
  User? currentUser = _User();
}

class _Storage extends Mock implements StorageProvider {
  Result<String> result = Result.success('https://example.org/photo');
  String? path;
  int uploads = 0;

  @override
  Future<Result<String>> uploadProfilePhoto(String uid, ProfilePhoto photo) async {
    uploads++;
    path = photo.pathFor(uid);
    return result;
  }
}

class _Api extends UnexpectedApiService {
  Map<String, dynamic>? payload;
  final statuses = <int>[];
  final requests = <Map<String, dynamic>>[];

  @override
  Future<Result<T>> put<T>(String endpoint, {dynamic data}) async {
    payload = data as Map<String, dynamic>;
    requests.add(Map.of(payload!));
    if (statuses.isNotEmpty) return Result.failure('Save failed', statusCode: statuses.removeAt(0));
    return Result.success(null);
  }
}

class _ProfileRef extends Fake implements DocumentReference<Map<String, dynamic>> {}

class _Users extends Fake implements CollectionReference<Map<String, dynamic>> {
  final profile = _ProfileRef();
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    expect(path, 'owner');
    return profile;
  }
}

class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? fields;
  _Snapshot(this.fields);

  @override
  Map<String, dynamic>? data() => fields;
}

class _Transaction extends Fake implements Transaction {
  final _Users users;
  final Map<String, dynamic>? fields;
  final writes = <Map<Object, Object?>>[];
  _Transaction(this.users, this.fields);

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(DocumentReference<T> ref) async {
    expect(ref, same(users.profile));
    return _Snapshot(fields) as DocumentSnapshot<T>;
  }

  @override
  Transaction update(DocumentReference ref, Map<Object, Object?> data) {
    expect(ref, same(users.profile));
    writes.add(data);
    return this;
  }
}

class _Firestore extends Fake implements FirebaseFirestore {
  final users = _Users();
  final Map<String, dynamic>? fields;
  late final transaction = _Transaction(users, fields);
  int transactions = 0;
  _Firestore([this.fields]);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    expect(path, 'users');
    return users;
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    transactions++;
    return handler(transaction);
  }
}

Future<Result<ProfilePhoto>> readPhoto(List<int> bytes) =>
    ProfilePhoto.read(XFile.fromData(Uint8List.fromList(bytes), name: 'selected.jpg'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads legacy and current saved photo fields', () {
    expect(
      UserCredentials.storedPhotoUrl({'photoUrl': ' ', 'photoURL': 'https://example.org/a'}),
      'https://example.org/a',
    );
    expect(UserCredentials.storedPhotoUrl({'photoUrl': 'https://example.org/b'}), 'https://example.org/b');
    expect(UserCredentials.storedPhotoUrl({}), isNull);
  });

  test('rejects unsupported, empty and limit-sized files', () async {
    for (final bytes in [
      <int>[],
      [1, 2, 3],
      [0xff, 0xd8],
      Uint8List(ProfilePhoto.maxBytes),
    ]) {
      expect((await readPhoto(bytes)).isSuccess, isFalse);
    }
  });

  test('photo-only save writes the uploaded URL with the backend field name', () async {
    final photo = (await readPhoto(File('assets/images/profile.png').readAsBytesSync())).value!;
    final storage = _Storage();
    final api = _Api();
    final vm = EditProfileViewModel(repository: EditProfileRepository(api, storage, _Auth(), _Firestore()));
    expect((await vm.saveProfile(uid: 'owner', photo: photo)).isSuccess, isTrue);
    expect(api.payload, {'photoURL': storage.result.value});
    expect(storage.path, startsWith('user_images/owner/'));
    expect(photo.contentType, 'image/png');
    final replacement = (await readPhoto(File('assets/images/profile_profile_icon.png').readAsBytesSync())).value!;
    expect(photo.pathFor('owner'), isNot(replacement.pathFor('owner')));
  });

  test('repairs a username-only profile after a 404 and retries the same save without re-uploading', () async {
    final photo = (await readPhoto(File('assets/images/profile.png').readAsBytesSync())).value!;
    final api = _Api()..statuses.add(404);
    final firestore = _Firestore({'username': 'test1'});
    final storage = _Storage();
    final repository = EditProfileRepository(api, storage, _Auth(), firestore);
    final result = await repository.updateProfile(uid: 'owner', photo: photo, displayName: 'Brad');
    expect(result.isSuccess, isTrue);
    expect(firestore.transaction.writes, [{'id': 'owner'}]);
    expect(api.requests, List.filled(2, {'photoURL': storage.result.value, 'displayName': 'Brad'}));
    expect(storage.uploads, 1);
  });

  test('does not create missing profiles or change conflicting identity fields', () async {
    final photo = (await readPhoto(File('assets/images/profile.png').readAsBytesSync())).value!;
    for (final fields in [null, {'id': 'other'}, {'firebaseUid': 'other'}]) {
      final api = _Api()..statuses.add(404);
      final firestore = _Firestore(fields);
      final repository = EditProfileRepository(api, _Storage(), _Auth(), firestore);
      expect((await repository.updateProfile(uid: 'owner', photo: photo)).isSuccess, isFalse);
      expect(firestore.transaction.writes, isEmpty);
      expect(api.requests, hasLength(1));
    }
  });

  test('retries only once and leaves an already-linked profile alone', () async {
    final photo = (await readPhoto(File('assets/images/profile.png').readAsBytesSync())).value!;
    final api = _Api()..statuses.addAll([404, 404]);
    final firestore = _Firestore({'id': 'owner'});
    final repository = EditProfileRepository(api, _Storage(), _Auth(), firestore);
    expect((await repository.updateProfile(uid: 'owner', photo: photo)).isSuccess, isFalse);
    expect(api.requests, hasLength(2));
    expect(firestore.transactions, 1);
    expect(firestore.transaction.writes, isEmpty);
  });

  test('other errors and text-only saves do not trigger profile repair', () async {
    final photo = (await readPhoto(File('assets/images/profile.png').readAsBytesSync())).value!;
    final api = _Api()..statuses.addAll([403, 404]);
    final firestore = _Firestore();
    final repository = EditProfileRepository(api, _Storage(), _Auth(), firestore);
    expect((await repository.updateProfile(uid: 'owner', photo: photo)).isSuccess, isFalse);
    expect((await repository.updateProfile(uid: 'owner', displayName: 'Brad')).isSuccess, isFalse);
    expect(firestore.transactions, 0);
  });

  test('failed upload or changed account leaves the saved URL alone', () async {
    final photo = (await readPhoto(File('assets/images/profile.png').readAsBytesSync())).value!;
    final api = _Api();
    final auth = _Auth();
    final storage = _Storage()..result = Result.failure('Upload failed');
    final repository = EditProfileRepository(api, storage, auth, _Firestore());
    expect((await repository.updateProfile(uid: 'owner', photo: photo)).isSuccess, isFalse);
    expect(api.payload, isNull);
    auth.currentUser = null;
    storage.result = Result.success('https://example.org/other');
    expect((await repository.updateProfile(uid: 'owner', photo: photo)).isSuccess, isFalse);
    expect(api.payload, isNull);
  });
}
