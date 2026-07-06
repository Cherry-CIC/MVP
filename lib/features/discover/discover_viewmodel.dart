import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:flutter/cupertino.dart';

class DiscoverViewModel extends ChangeNotifier {
  final DiscoverRepository discoverRepository;

  DiscoverViewModel({required this.discoverRepository});

  List<DummyCharity> fetchCharities() {
    return discoverRepository.fetchCharities();
  }

  List<Product> fetchProducts() {
    return discoverRepository.fetchProducts();
  }
}
