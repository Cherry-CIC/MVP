import 'package:cherry_mvp/core/models/donation_charity_model.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';

abstract class ICharityRepository {
  Future<Result<List<CharityCategories>>> fetchCharities();
}

final class CharityRepository implements ICharityRepository {
  final ApiService _apiService;

  CharityRepository(this._apiService);

  @override
  Future<Result<List<CharityCategories>>> fetchCharities() {
    return getCharityCategories();
  }

  Future<Result<List<CharityCategories>>> getCharityCategories() async {
    try {
      final result = await _apiService.get(ApiEndpoints.charities);

      if (result.isSuccess && result.value != null) {
        final data = result.value;

        // Extract list correctly
        final List<dynamic> jsonList = data['data'] ?? data;

        // Convert Iterable → List
        final charities = jsonList
            .map((json) => CharityCategories.fromJson(json))
            .toList();

        return Result.success(charities);
      } else {
        return Result.failure(result.error ?? 'Failed to fetch charities');
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}


final class CharityRepositoryMock implements ICharityRepository {
  @override
  Future<Result<List<CharityCategories>>> fetchCharities() async {
    return Result.success(dummyCharities);
  }
}
