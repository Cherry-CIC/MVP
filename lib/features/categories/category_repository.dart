import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/utils/utils.dart';

abstract class ICategoryRepository {
  Future<Result<List<Category>>> fetchCategories();
}

final class CategoryRepository implements ICategoryRepository {
  final ApiService _apiService;
  CategoryRepository(this._apiService);

  @override
  Future<Result<List<Category>>> fetchCategories() async {
    try {
      final result = await _apiService.get(ApiEndpoints.categories);

      if (result.isSuccess && result.value != null) {
        final data = result.value;
        final List<dynamic> jsonList = data['data'] ?? data;
        final categories =
            jsonList.map((json) => Category.fromJson(json)).toList();
        return Result.success(categories);
      } else {
        return Result.failure(result.error ?? 'Failed to fetch categories');
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
