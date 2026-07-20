import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/features/discover/discover_model.dart';

class DiscoverRepository {
  List<DummyCharity> fetchCharities({String? tag}) {
    if (tag == null) {
      return dummyCharities;
    }

    return dummyCharities.where((charity) => charity.tags.contains(tag)).toList();
  }

  List<Product> fetchProducts() {
    return dummyProducts;
  }
}
