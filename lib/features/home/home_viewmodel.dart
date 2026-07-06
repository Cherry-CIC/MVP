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
        _status = Status.failure(result.error ?? 'Failed to fetch products');
        _log.warning('Fetch products failed! ${result.error}');
      }
    } catch (e) {
      _status = Status.failure(e.toString());
      _log.severe('Fetch products error: $e');
    }

    notifyListeners();
  }
}
