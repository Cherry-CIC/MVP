import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';

class HomeViewModel extends ChangeNotifier {

  final _log = Logger('HomeViewModel');
  final HomeRepository homeRepository;

  HomeViewModel({required this.homeRepository});

  List<Category> fetchCategories()  {
    return homeRepository.fetchCategories();
  }

  List<Product> fetchProducts()  {
    return homeRepository.fetchProducts();
  }
  
  List<CharityLogo> fetchCharityLogos()  {
    return homeRepository.fetchCharityLogos();
  }
}
