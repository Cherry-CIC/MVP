import 'package:flutter/foundation.dart';

/// Confirmed deletions remain hidden for this app session, including across
/// account changes and responses from requests started before deletion.
class DeletedListings extends ChangeNotifier {
  final Set<String> _ids = {};

  bool contains(String id) => _ids.contains(id.trim());

  void add(String id) {
    final listingId = id.trim();
    if (listingId.isEmpty || !_ids.add(listingId)) return;
    notifyListeners();
  }
}
