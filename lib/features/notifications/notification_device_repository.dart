import 'package:cherry_mvp/core/config/environment_config.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract interface class NotificationDeviceRepository {
  Future<bool> register({required String userId, required String token, required String platform});
  Future<bool> unregister({required String userId, required String token});
}

class ApiNotificationDeviceRepository implements NotificationDeviceRepository {
  ApiNotificationDeviceRepository({required this.auth, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppEnvironment.apiBaseUrl,
              connectTimeout: const Duration(seconds: 8),
              sendTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );
  final FirebaseAuth auth;
  final Dio _dio;

  Future<bool> _send(String method, String userId, Map<String, String> data) async {
    // Capture this session's user. A shared interceptor reading currentUser
    // later could otherwise register a previous account's token for a new one.
    final user = auth.currentUser;
    if (user == null || user.uid != userId) return false;
    try {
      final bearer = await user.getIdToken().timeout(const Duration(seconds: 8));
      if (bearer == null || bearer.isEmpty || auth.currentUser?.uid != userId) return false;
      final response = await _dio.request<Map<String, dynamic>>(
        '/api/notifications/devices',
        data: data,
        options: Options(method: method, headers: {'Authorization': 'Bearer $bearer'}),
      );
      return response.data?['success'] == true;
    } catch (_) {
      // Includes rollout-disabled (503), offline and expired sessions. Never
      // expose or log a registration token, bearer token or response payload.
      return false;
    }
  }

  @override
  Future<bool> register({required String userId, required String token, required String platform}) =>
      _send('POST', userId, {'token': token, 'platform': platform});
  @override
  Future<bool> unregister({required String userId, required String token}) => _send('DELETE', userId, {'token': token});
}
