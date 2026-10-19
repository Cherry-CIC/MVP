import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';

enum ReportTargetType {
  product('product'),
  user('user');

  const ReportTargetType(this.apiValue);

  final String apiValue;
}

class SafetyRepository {
  SafetyRepository(this._apiService);

  static const String _reportFailureMessage = 'Could not submit this report.';
  static const String _blockFailureMessage = 'Could not block this seller.';

  final ApiService _apiService;

  Future<Result<void>> submitReport({
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
    String? message,
  }) async {
    final cleanTargetId = targetId.trim();
    final cleanReason = reason.trim();
    final cleanMessage = (message ?? '').trim();
    if (cleanTargetId.isEmpty || cleanTargetId.contains('/') || cleanReason.isEmpty) {
      return Result.failure('Please choose a valid report reason.');
    }

    final payload = <String, dynamic>{
      'targetType': targetType.apiValue,
      'targetId': cleanTargetId,
      'reason': cleanReason,
      if (cleanMessage.isNotEmpty) 'message': cleanMessage,
    };

    try {
      final result = await _apiService.post<dynamic>(
        ApiEndpoints.reports,
        data: payload,
      );
      if (!result.isSuccess || result.value == null) {
        return Result.failure(result.error ?? _reportFailureMessage);
      }

      final response = result.value;
      if (response is Map && response['success'] == false) {
        return Result.failure(_reportFailureMessage);
      }
      return Result.success(null);
    } catch (_) {
      return Result.failure(_reportFailureMessage);
    }
  }

  Future<Result<void>> blockUser(String userId) async {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty || cleanUserId.contains('/')) {
      return Result.failure('Could not block this seller.');
    }

    try {
      final result = await _apiService.post<dynamic>(
        ApiEndpoints.blockUser(cleanUserId),
      );
      if (!result.isSuccess || result.value == null) {
        return Result.failure(result.error ?? _blockFailureMessage);
      }

      final response = result.value;
      if (response is Map && response['success'] == false) {
        return Result.failure(_blockFailureMessage);
      }
      return Result.success(null);
    } catch (_) {
      return Result.failure(_blockFailureMessage);
    }
  }
}
