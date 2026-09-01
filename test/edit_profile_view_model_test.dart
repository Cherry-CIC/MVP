import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/profile/edit_profile_repository.dart';
import 'package:cherry_mvp/features/profile/edit_profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEditProfileRepository implements IEditProfileRepository {
  _FakeEditProfileRepository({Result<void>? updateResult})
      : updateResult = updateResult ?? Result.success(null);

  Result<void> updateResult;
  int updateCount = 0;
  String? lastDisplayName;
  String? lastPhoneNumber;

  @override
  Future<Result<void>> updateProfile({
    String? displayName,
    String? phoneNumber,
  }) async {
    updateCount += 1;
    lastDisplayName = displayName;
    lastPhoneNumber = phoneNumber;
    return updateResult;
  }
}

void main() {
  group('EditProfileViewModel', () {
    test('sends changed fields to the repository and reports success',
        () async {
      final repository = _FakeEditProfileRepository();
      final viewModel = EditProfileViewModel(repository: repository);

      final result = await viewModel.saveProfile(
        uid: 'uid-1',
        firstName: 'Joshua',
        phoneNumber: '07123456789',
      );

      expect(result.isSuccess, isTrue);
      expect(repository.updateCount, 1);
      expect(repository.lastDisplayName, 'Joshua');
      expect(repository.lastPhoneNumber, '07123456789');
      expect(viewModel.status.type, StatusType.success);
    });

    test('only sends the fields that changed', () async {
      final repository = _FakeEditProfileRepository();
      final viewModel = EditProfileViewModel(repository: repository);

      final result = await viewModel.saveProfile(
        uid: 'uid-1',
        phoneNumber: '07123456789',
      );

      expect(result.isSuccess, isTrue);
      expect(repository.lastDisplayName, isNull);
      expect(repository.lastPhoneNumber, '07123456789');
    });

    test('does not call the repository when nothing changed', () async {
      final repository = _FakeEditProfileRepository();
      final viewModel = EditProfileViewModel(repository: repository);

      final result = await viewModel.saveProfile(uid: 'uid-1');

      expect(result.isSuccess, isTrue);
      expect(repository.updateCount, 0);
    });

    test('surfaces repository failures', () async {
      final repository = _FakeEditProfileRepository(
        updateResult: Result.failure('server unavailable'),
      );
      final viewModel = EditProfileViewModel(repository: repository);

      final result = await viewModel.saveProfile(
        uid: 'uid-1',
        firstName: 'Joshua',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, 'server unavailable');
      expect(viewModel.status.type, StatusType.failure);
    });
  });
}
