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
        final jsonList = data is Map ? data['data'] : data;
        if (jsonList is! List) {
          return Result.failure('Unexpected categories response');
        }
        final categories = <Category>[];
        for (final json in jsonList) {
          if (json is! Map) continue;
          try {
            final category = Category.fromJson(Map<String, dynamic>.from(json));
            if (category.id.trim().isNotEmpty && category.name.trim().isNotEmpty) {
              categories.add(category);
            }
          } on FormatException {
            // An invalid date must not hide the remaining categories.
            continue;
          } on TypeError {
            // An incomplete record must not hide the remaining categories.
            continue;
          }
        }
        return Result.success(categories);
      } else {
        return Result.failure(result.error ?? 'Failed to fetch categories');
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
