import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/features/discover/discover_model.dart';

class DiscoverRepository {
  static String normalizeCharityName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceFirst(RegExp(r'^the\s+'), '')
        .replaceAll(RegExp(r'[\s\-]+'), '');
  }

  String? descriptionForCharityName(String name) {
    // Discovery's local catalogue has no API charity IDs, so match full names
    // (ignoring spacing, hyphen, and leading-"The" variations) rather than
    // risking a description from a partial name match.
    final normalisedName = normalizeCharityName(name);
    if (normalisedName.isEmpty) {
      return null;
    }
    for (final charity in fetchCharities()) {
      if (normalizeCharityName(charity.charityName) == normalisedName) {
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
