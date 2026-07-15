import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:logging/logging.dart';
import 'home_model.dart';

abstract class IHomeRepository {
  Future<Result<List<Product>>> fetchProducts();
}

final class HomeRepository implements IHomeRepository {
  final ApiService _apiService;
  final _log = Logger('HomeRepository');

  HomeRepository(this._apiService);

  @override
  Future<Result<List<Product>>> fetchProducts() async {
    try {
      _log.info('Fetching products from API...');
      final result = await _apiService.get(ApiEndpoints.productsWithDetails);

      if (result.isSuccess && result.value != null) {
        _log.info('API call successful, parsing response...');
        final data = result.value;
        
        // Try different response structures
        List<dynamic> jsonList = [];
        if (data is List) {
          jsonList = data;
        } else if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            jsonList = data['data'] ?? [];
          } else if (data.containsKey('products')) {
            jsonList = data['products'] ?? [];
          } else {
            _log.warning('Unexpected response structure, treating as single item');
            jsonList = [data];
          }
        }
        
        final List<Product> products = [];
        for (int i = 0; i < jsonList.length; i++) {
          try {
            final json = jsonList[i];
            final product = Product.fromJson(json);
            products.add(product);
          } catch (e) {
            _log.warning('Failed to parse product $i: $e');
          }
        }
        
        _log.info('Successfully parsed ${products.length} products');
        return Result.success(products);
      } else {
        _log.warning('API call failed: ${result.error}');
        return Result.failure(result.error ?? 'Failed to fetch products');
      }
    } catch (e) {
      _log.severe('Exception during product fetch: $e');
      return Result.failure(e.toString());
    }
  }
}

final class HomeRepositoryMock implements IHomeRepository {

  @override
  Future<Result<List<Product>>> fetchProducts() async {
    return Result.success(dummyProducts);
  }
}