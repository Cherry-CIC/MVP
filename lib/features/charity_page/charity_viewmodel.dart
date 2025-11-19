import 'package:cherry_mvp/core/models/donation_charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_repository.dart';

import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';

class CharityViewModel extends ChangeNotifier {

  final _log = Logger('CharityViewModel');
  final ICharityRepository charityRepository;

  CharityViewModel({required this.charityRepository});

  // Private variables
  Status _status = Status.uninitialized;
  List<CharityCategories> _charities = [];

  // Public getters
  Status get status => _status;
  List<CharityCategories> get charities => _charities;

  Future<void> fetchCharities() async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await charityRepository.fetchCharities();
      
      if (result.isSuccess && result.value != null) {
        _charities = result.value!;
        _status = Status.success;
      } else {
        _status = Status.failure(result.error ?? 'Failed to fetch charities');
        _log.warning('Fetch charities failed! ${result.error}');
      }
    } catch (e) {
      _status = Status.failure(e.toString());
      _log.severe('Fetch charities error: $e');
    }

    notifyListeners();
  }
}