import 'package:cherry_mvp/core/services/error_string.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';

class HomeViewModel extends ChangeNotifier {
  final _log = Logger('HomeViewModel');
  final IHomeRepository homeRepository;

  HomeViewModel({required this.homeRepository});

  // Private variables
  Status _status = Status.uninitialized;
  List<Product> _products = [];

  // Public getters
  Status get status => _status;
  List<Product> get products => _products;

  Future<void> fetchProducts() async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await homeRepository.fetchProducts();

      if (result.isSuccess && result.value != null) {
        _products = result.value!;
        _status = Status.success;
      } else {
        _log.warning('Fetch products failed! ${result.error}');
        _status = Status.failure(ErrorStrings.productsLoadError);
      }
    } catch (e) {
      _log.severe('Fetch products error: $e');
      _status = Status.failure(ErrorStrings.productsLoadError);
    }

    notifyListeners();
  }
}
