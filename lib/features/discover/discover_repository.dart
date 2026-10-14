import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/features/discover/discover_model.dart';

class DiscoverRepository {
  String? descriptionForCharityName(String name) {
    // Discovery's local catalogue has no API charity IDs, so match full names
    // rather than risking a description from a partial name match.
    String normalise(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final normalisedName = normalise(name);
    for (final charity in fetchCharities()) {
      if (normalise(charity.charityName) == normalisedName) {
        final description = charity.description.trim();
        return description.isEmpty ? null : description;
      }
    }
    return null;
  }

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
