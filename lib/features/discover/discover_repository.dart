import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/features/discover/discover_model.dart';

class DiscoverRepository {

  List<DummyCharity> fetchCharities()  {
    return dummyCharities;
  }

  List<Product> fetchProducts()  {
    return dummyProducts;
  }
}