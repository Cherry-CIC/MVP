import 'package:cherry_mvp/core/config/firestore_constants.dart';
import 'package:cherry_mvp/core/models/inpost_model.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ICheckoutRepository {
  Future<Result> fetchNearestInPosts(String postalCode);

  Future<void> storeLockerInFirestore(InpostModel data);

  /// Store a dummy order in Firestore
  Future<void> storeOrderInFirestore(Map<String, dynamic> orderData);

  Future<Result<DocumentSnapshot>> fetchUserLocker();

  Future<Result<PaymentIntentResponse>> createPaymentIntent(int amount);
}

final class CheckoutRepository implements ICheckoutRepository {
  final ApiService _apiService;
  final FirestoreService _firestoreService;
  CheckoutRepository(this._apiService, this._firestoreService);

  @override
  Future<Result> fetchNearestInPosts(String postalCode) async {
    try {
      final result = await _apiService.get(
        "${ApiEndpoints.inpostLockers} ?postcode=$postalCode&maxDistance=30",
      );
      if (result.isSuccess && result.value != null) {
        final data = result.value;

        final jsonList = data['data'] ?? data;
        //<List<Locker>>
        // final categories =
        //     jsonList.map((json) => Category.fromJson(json)).toList();
        return Result.success(jsonList);
      } else {
        return Result.failure(
          result.error ??
              'Pickup points currently unavailable, please try again later',
        );
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<void> storeLockerInFirestore(InpostModel data) async {
    Map<String, dynamic> lockerData = {
      FirestoreConstants.id: data.id,
      FirestoreConstants.name: data.name,
      FirestoreConstants.address: data.address,
      FirestoreConstants.postcode: data.postcode,
      FirestoreConstants.lat: data.lat,
      FirestoreConstants.long: data.long,
    };

    await _firestoreService.saveDocument(
      FirestoreConstants.orders,
      FirestoreConstants.pickup,
      lockerData,
      isOrder: true,
    );
  }

  @override
  Future<void> storeOrderInFirestore(Map<String, dynamic> orderData) async {
    // Use a generated order ID (timestamp-based)
    final orderId = DateTime.now().millisecondsSinceEpoch.toString();
    await _firestoreService.saveDocument(
      FirestoreConstants.orders,
      orderId,
      orderData,
      isOrder: true,
    );
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
  Future<Result<PaymentIntentResponse>> createPaymentIntent(int amount) async {
    //  call backend API which returns client_secret
    var data = {"amount": amount};

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
}
