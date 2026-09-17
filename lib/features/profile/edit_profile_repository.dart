import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/utils/utils.dart';

abstract class IEditProfileRepository {
  Future<Result<void>> updateProfile({
    String? displayName,
    String? phoneNumber,
  });
}

class EditProfileRepository implements IEditProfileRepository {
  final ApiService apiService;

  EditProfileRepository(this.apiService);

  @override
  Future<Result<void>> updateProfile({
    String? displayName,
    String? phoneNumber,
  }) async {
    final result = await apiService.put<Map<String, dynamic>>(
      ApiEndpoints.profile,
      data: {
        'displayName': ?displayName,
        'phoneNumber': ?phoneNumber,
      },
    );

    if (!result.isSuccess) {
      return Result.failure(result.error ?? AppStrings.editProfileSaveFailed);
    }

    final response = result.value;
    if (response != null && response['success'] == false) {
      return Result.failure(
        response['message']?.toString() ?? AppStrings.editProfileSaveFailed,
      );
    }

    return Result.success(null);
  }
}
