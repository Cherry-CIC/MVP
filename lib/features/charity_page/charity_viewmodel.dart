import 'package:flutter/cupertino.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_repository.dart';

class CharityViewModel extends ChangeNotifier {
  final ICharityRepository charityRepository;
  final NavigationProvider navigator;

  CharityViewModel({required this.charityRepository, required this.navigator});

  // Private variables
  Status _status = Status.uninitialized;
  List<Charity> _charities = [];
  Future<void>? _charitiesRequest;

  // Public getters
  Status get status => _status;
  List<Charity> get charities => _charities;

  Future<void> ensureCharitiesLoaded() {
    if (_status.type == StatusType.success) {
      return Future<void>.value();
    }
    return fetchCharities();
  }

  Future<void> fetchCharities() {
    final request = _charitiesRequest;
    if (request != null) return request;

    _status = Status.loading;
    notifyListeners();

    final newRequest = _loadCharities();
    _charitiesRequest = newRequest;
    newRequest.whenComplete(() {
      if (identical(_charitiesRequest, newRequest)) {
        _charitiesRequest = null;
      }
    });
    return newRequest;
  }

  Future<void> _loadCharities() async {
    try {
      final result = await charityRepository.fetchCharities();

      if (result.isSuccess && result.value != null) {
        _charities = result.value!;
        _status = Status.success;
      } else {
        _status = Status.failure(result.error ?? 'Failed to fetch charities');
        SafeLog.event(
          AppLogEvent.charityLoadFailed,
          level: SafeLogLevel.warning,
        );
      }
    } catch (e) {
      _status = Status.failure(e.toString());
      SafeLog.event(
        AppLogEvent.charityLoadFailed,
        level: SafeLogLevel.severe,
      );
    }

    notifyListeners();
  }

  void goBack([Charity? charity]) {
    navigator.goBack(charity);
  }
}
