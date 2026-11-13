import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';

enum ReportTargetType {
  product('product'),
  user('user'),
  charity('charity');

  const ReportTargetType(this.apiValue);

  final String apiValue;
}

class SafetyRepository {
  SafetyRepository(this._apiService);

  static const String _reportFailureMessage = 'Could not submit this report.';
  static const String _blockUserFailureMessage = 'Could not block this seller.';
  static const String _blockCharityFailureMessage =
      'Could not block this charity.';

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

  Future<Result<void>> blockUser(String userId) {
    final cleanUserId = userId.trim();
    return _postSafetyBlock(
      cleanTargetId: cleanUserId,
      endpoint: ApiEndpoints.blockUser(cleanUserId),
      failureMessage: _blockUserFailureMessage,
    );
  }

  /// Blocks [charityId] for the signed-in viewer.
  Future<Result<void>> blockCharity(String charityId) {
    final cleanCharityId = charityId.trim();
    return _postSafetyBlock(
      cleanTargetId: cleanCharityId,
      endpoint: ApiEndpoints.blockCharity(cleanCharityId),
      failureMessage: _blockCharityFailureMessage,
    );
  }

  Future<Result<void>> _postSafetyBlock({
    required String cleanTargetId,
    required String endpoint,
    required String failureMessage,
  }) async {
    if (cleanTargetId.isEmpty ||
        cleanTargetId == '.' ||
        cleanTargetId == '..' ||
        cleanTargetId.contains('/')) {
      return Result.failure(failureMessage);
    }

    try {
      final result = await _apiService.post<dynamic>(endpoint);
      if (!result.isSuccess || result.value == null) {
        return Result.failure(result.error ?? failureMessage);
      }

      final response = result.value;
      if (response is Map && response['success'] == false) {
        return Result.failure(failureMessage);
      }
      return Result.success(null);
    } catch (_) {
      return Result.failure(failureMessage);
    }
  }
}
