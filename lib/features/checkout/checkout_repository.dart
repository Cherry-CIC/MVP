import 'package:cherry_mvp/core/models/model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cherry_mvp/core/config/firestore_constants.dart';
import 'package:cherry_mvp/core/models/inpost.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';

abstract class ICheckoutRepository {
  Future<Result> fetchNearestInposts(String postalCode, String country);
  Future<Result> fetchShippingMethodsForInpost(String servicePointId, String postalCode, String country);

  Future<void> storeLockerInFirestore(Inpost data);

  /// Store a dummy order in Firestore
  Future<void> storeOrderInFirestore(Map<String, dynamic> orderData);

  Future<Result<DocumentSnapshot>> fetchUserLocker();

  Future<Result<PaymentIntentResponse>> createPaymentIntent(double amount);
  Future<Result> createOrder(Map<String, dynamic> order);
  Future<Result<UserCredentials>> fetchUserProfile();
}

final class CheckoutRepository implements ICheckoutRepository {
  final ApiService _apiService;
  final FirestoreService _firestoreService;
  CheckoutRepository(this._apiService, this._firestoreService);

  @override
  Future<Result> fetchNearestInposts(String postalCode, String country) async {
    try {
      final result = await _apiService.get(
        "${ApiEndpoints.inpostLockers}?country=$country&address=$postalCode&radius=1000",
      );
      if (result.isSuccess && result.value != null) {
        final data = result.value;
        final jsonList = data is Map<String, dynamic>
            ? (data['data'] ?? data['lockers'] ?? data['items'] ?? data)
            : data;
        return Result.success(jsonList);
      } else {
        return Result.failure(
          result.error ?? 'Pickup points currently unavailable, please try again later',
        );
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<dynamic>> fetchShippingMethodsForInpost(
    String servicePointId,
    String postalCode,
    String country,
  ) async {
    try {
      final result = await _apiService.get(
        "${ApiEndpoints.inpostShippingMethods}?servicePointId=$servicePointId&country=$country&postalCode=$postalCode",
      );
      if (result.isSuccess && result.value != null) {
        final data = result.value;
        final jsonList = data is Map<String, dynamic>
            ? (data['data'] ?? data['lockers'] ?? data['items'] ?? data)
            : data;
        return Result.success(jsonList);
      } else {
        return Result.failure(
          result.error ?? 'Pickup points currently unavailable, please try again later',
        );
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<void> storeLockerInFirestore(Inpost data) async {
    Map<String, dynamic> lockerData = {
      FirestoreConstants.id: data.id,
      FirestoreConstants.name: data.name,
      FirestoreConstants.address: data.address,
      FirestoreConstants.postcode: data.postcode,
      FirestoreConstants.city: data.city,
      FirestoreConstants.country: data.country,
      FirestoreConstants.lat: data.lat,
      FirestoreConstants.long: data.long,
    };

    final result = await _firestoreService.saveDocument(
      FirestoreConstants.orders,
      FirestoreConstants.pickup,
      lockerData,
      isOrder: true,
    );

    if (!result.isSuccess) {
      throw StateError(
        result.error ?? 'Unable to store pickup locker in Firestore.',
      );
    }
  }

  @override
  Future<void> storeOrderInFirestore(Map<String, dynamic> orderData) async {
    // Use a generated order ID (timestamp-based)
    final orderId = DateTime.now().millisecondsSinceEpoch.toString();
    final uid = _firestoreService.currentUserId;
    final payload = {
      ...orderData,
      'user_id': uid ?? '',
      'updated_at': DateTime.now().toIso8601String(),
    };

    final result = await _firestoreService.saveDocument(
      FirestoreConstants.orders,
      orderId,
      payload,
      isOrder: false,
    );

    if (!result.isSuccess) {
      throw StateError(result.error ?? 'Unable to store order in Firestore.');
    }
  }

  @override
  Future<Result<DocumentSnapshot>> fetchUserLocker() async {
    final result = await _firestoreService.getDocument(
      FirestoreConstants.orders,
      FirestoreConstants.pickup,
      isOrder: true,
    );
    return result;
  }

  @override
  Future<Result<PaymentIntentResponse>> createPaymentIntent(
    double amount,
  ) async {
    //  call backend API which returns client_secret
    final int amountInMinorUnits = (amount * 100).round();
    var data = {"amount": amountInMinorUnits};

    try {
      final result = await _apiService.post(
        ApiEndpoints.paymentIntent,
        data: data,
      );
      if (result.isSuccess) {
        final paymentResponse = PaymentIntentResponse.fromJson(result.value);
        return Result.success(paymentResponse);
      } else {
        return Result.failure(
          result.error ?? 'Error creating payment, please try again later',
        );
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result> createOrder(Map<String, dynamic> order) async {
    try {
      final result = await _apiService.post(
        ApiEndpoints.createOrder,
        data: order,
      );
      if (result.isSuccess && result.value != null) {
        final data = result.value;

        final jsonList = data['data'] ?? data;

        return Result.success(jsonList);
      } else {
        return Result.failure(
          result.error ?? 'Error creating payment, please try again later',
        );
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<UserCredentials>> fetchUserProfile() async {
    try {
      final result = await _apiService.get(ApiEndpoints.profile);

      if (result.isSuccess && result.value != null) {
        final data = result.value['data'];
        final userProfile = UserCredentials.fromFirestore(data, data['id']);
        return Result.success(userProfile);
      } else {
        return Result.failure(
          result.error ?? 'Error fetching profile, please try again later',
        );
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
