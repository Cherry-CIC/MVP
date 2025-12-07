import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/categories/category_repository.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class CategoryViewModel extends ChangeNotifier {
  final ICategoryRepository categoryRepository;
  final _log = Logger('CategoryViewModel');

  CategoryViewModel({required this.categoryRepository});

  Status _status = Status.uninitialized;

  Status get status => _status;

  List<Category> _categories = [];

  List<Category> get categories => _categories;

  final List<String> _categoryOrder = [
    'Women',
    'Men',
    'Children',
    'Accessories',
    'Unisex',
    'Designer',
    'Books',
    'Toys & Board Game',
    'CD’s & Vinyl',
    'DVD’s & Video Games',
  ];

  void _sortCategories() {
    _categories.sort((a, b) {
      final indexA = _categoryOrder.indexOf(a.name);
      final indexB = _categoryOrder.indexOf(b.name);

      if (indexA != -1 && indexB != -1) {
        return indexA.compareTo(indexB);
      } else if (indexA != -1) {
        return -1;
      } else if (indexB != -1) {
        return 1;
      } else {
        return a.name.compareTo(b.name);
      }
    });
  }

  IconData? getCategoryIcon(String categoryName) {
    if ('DVD’s & Video Games'.contains(categoryName)) {
      return Icons.videogame_asset;
    }
    return null;
  }

  String? getCategoryAssetIcon(String categoryName) {
    if (categoryName.contains("Board Game")) {
      return AppImages.toysIcon;
    }
    return null;
  }

  Future<void> fetchCategories() async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await categoryRepository.fetchCategories();
      if (result.isSuccess && result.value != null) {
        _categories = result.value!;
        _sortCategories();
        _status = Status.success;
      } else {
        _status = Status.failure(result.error ?? 'Could not load categories');
        _log.warning('Fetch categories failed! ${result.error}');
      }
    } catch (e) {
      _status = Status.failure(e.toString());
      _log.severe('Fetch categories error:: $e');
    }

    notifyListeners();
  }
}
