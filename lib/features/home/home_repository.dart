import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/services/error_string.dart';
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

        if (data is Map<String, dynamic> && data['success'] == false) {
          _log.warning('Products API returned an unsuccessful response: $data');
          return Result.failure(ErrorStrings.productsLoadError);
        }

        final jsonList = _extractProductList(data);
        if (jsonList == null) {
          _log.warning('Unexpected products response structure: ${data.runtimeType}');
          return Result.failure(ErrorStrings.productsLoadError);
        }

        final List<Product> products = [];
        for (int i = 0; i < jsonList.length; i++) {
          try {
            final json = Map<String, dynamic>.from(jsonList[i] as Map);
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
        return Result.failure(ErrorStrings.productsLoadError);
      }
    } catch (e) {
      _log.severe('Exception during product fetch: $e');
      return Result.failure(ErrorStrings.productsLoadError);
    }
  }

  List<dynamic>? _extractProductList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final directData = data['data'];
      if (directData is List) {
        return directData;
      }

      if (directData is Map<String, dynamic>) {
        final nestedProducts = directData['products'];
        if (nestedProducts is List) {
          return nestedProducts;
        }
      }

      final directProducts = data['products'];
      if (directProducts is List) {
        return directProducts;
      }
    }

    return null;
  }
}

final class HomeRepositoryMock implements IHomeRepository {
  @override
  Future<Result<List<Product>>> fetchProducts() async {
    return Result.success(dummyProducts);
  }
}
