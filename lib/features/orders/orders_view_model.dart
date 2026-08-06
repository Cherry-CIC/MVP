import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/orders_repository.dart';
import 'package:flutter/foundation.dart';

class OrdersViewModel extends ChangeNotifier {
  final IOrdersRepository repository;

  OrdersViewModel({
    required this.repository,
  });

  Status _status = Status.uninitialized;
  List<OrderSummary> _orders = const [];
  bool _isRefreshing = false;
  String? _refreshError;
  int _requestSequence = 0;
  bool _isDisposed = false;

  Status get status => _status;
  List<OrderSummary> get orders => List.unmodifiable(_orders);
  bool get isRefreshing => _isRefreshing;
  String? get refreshError => _refreshError;

  Future<void> loadOrders() async {
    await _fetchOrders(clearExistingOrders: true);
  }

  Future<void> refreshOrders() async {
    await _fetchOrders(clearExistingOrders: false);
  }

  Future<void> retryLoad() async {
    await _fetchOrders(clearExistingOrders: true);
  }

  void clearOrders({bool notify = true}) {
    _requestSequence++;
    _orders = const [];
    _status = Status.uninitialized;
    _isRefreshing = false;
    _refreshError = null;

    if (notify) {
      _notifyIfActive();
    }
  }

  Future<void> _fetchOrders({
    required bool clearExistingOrders,
  }) async {
    if (_isDisposed) {
      return;
    }

    final requestId = ++_requestSequence;
    _refreshError = null;

    if (clearExistingOrders) {
      _orders = const [];
      _status = Status.loading;
      _isRefreshing = false;
    } else if (_orders.isEmpty) {
      _status = Status.loading;
      _isRefreshing = false;
    } else {
      _isRefreshing = true;
    }
    _notifyIfActive();

    try {
      final result = await repository.fetchOrders();
      if (!_isCurrentRequest(requestId)) {
        return;
      }

      if (result.isSuccess && result.value != null) {
        _orders = List.unmodifiable(result.value!);
        _status = Status.success;
      } else {
        final error = result.error ?? 'Could not load your orders';
        if (_orders.isEmpty) {
          _status = Status.failure(error);
        } else {
          _refreshError = error;
        }
      }
    } catch (_) {
      if (!_isCurrentRequest(requestId)) {
        return;
      }

      if (_orders.isEmpty) {
        _status = Status.failure('Could not load your orders');
      } else {
        _refreshError = 'Could not refresh your orders';
      }
    } finally {
      if (_isCurrentRequest(requestId)) {
        _isRefreshing = false;
        _notifyIfActive();
      }
    }
  }

  bool _isCurrentRequest(int requestId) {
    return !_isDisposed && requestId == _requestSequence;
  }

  void _notifyIfActive() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _requestSequence++;
    _orders = const [];
    _status = Status.uninitialized;
    _isRefreshing = false;
    _refreshError = null;
    _isDisposed = true;
    super.dispose();
  }
}
