import 'dart:io';
import 'dart:typed_data';

import 'package:cherry_mvp/core/models/profile_photo.dart';
import 'package:cherry_mvp/core/models/user.dart';
import 'package:cherry_mvp/core/services/firebase_storage.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/profile/edit_profile_repository.dart';
import 'package:cherry_mvp/features/profile/edit_profile_view_model.dart';
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

  @override
  Future<Result<String>> uploadProfilePhoto(String uid, ProfilePhoto photo) async {
    path = photo.pathFor(uid);
    return result;
  }
}

class _Api extends UnexpectedApiService {
  Map<String, dynamic>? payload;

  @override
  Future<Result<T>> put<T>(String endpoint, {dynamic data}) async {
    payload = data as Map<String, dynamic>;
    return Result.success(null);
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
    final vm = EditProfileViewModel(repository: EditProfileRepository(api, storage, _Auth()));
    expect((await vm.saveProfile(uid: 'owner', photo: photo)).isSuccess, isTrue);
    expect(api.payload, {'photoURL': storage.result.value});
    expect(storage.path, startsWith('user_images/owner/'));
    expect(photo.contentType, 'image/png');
    final replacement = (await readPhoto(File('assets/images/profile_profile_icon.png').readAsBytesSync())).value!;
    expect(photo.pathFor('owner'), isNot(replacement.pathFor('owner')));
  });

  test('failed upload or changed account leaves the saved URL alone', () async {
    final photo = (await readPhoto(File('assets/images/profile.png').readAsBytesSync())).value!;
    final api = _Api();
    final auth = _Auth();
    final storage = _Storage()..result = Result.failure('Upload failed');
    final repository = EditProfileRepository(api, storage, auth);
    expect((await repository.updateProfile(uid: 'owner', photo: photo)).isSuccess, isFalse);
    expect(api.payload, isNull);
    auth.currentUser = null;
    storage.result = Result.success('https://example.org/other');
    expect((await repository.updateProfile(uid: 'owner', photo: photo)).isSuccess, isFalse);
    expect(api.payload, isNull);
  });
}
