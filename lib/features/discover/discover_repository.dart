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

  DummyCharity? findCharity({String? id, String? name}) {
    final trimmedId = id?.trim();
    if (trimmedId != null && trimmedId.isNotEmpty) {
      for (final charity in fetchCharities()) {
        if (charity.id == trimmedId) {
          return charity;
        }
      }
    }

    if (name != null) {
      final normalisedName = normalizeCharityName(name);
      if (normalisedName.isNotEmpty) {
        for (final charity in fetchCharities()) {
          if (normalizeCharityName(charity.charityName) == normalisedName) {
            return charity;
          }
        }
      }
    }

    return null;
  }

  String? descriptionForCharityName(String name) {
    // Match full names (ignoring spacing, hyphen, and leading-"The"
    // variations) rather than risking a description from a partial match.
    final charity = findCharity(name: name);
    final description = charity?.description.trim();
    return (description == null || description.isEmpty) ? null : description;
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
