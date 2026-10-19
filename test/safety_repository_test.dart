import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/products/safety_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingApiService implements ApiService {
  String? lastPostEndpoint;
  dynamic lastPostData;

  @override
  Future<Result<T>> post<T>(String endpoint, {dynamic data}) async {
    lastPostEndpoint = endpoint;
    lastPostData = data;
    return Result.success(const {'success': true} as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('submits product reports with the expected payload', () async {
    final apiService = _RecordingApiService();
    final repository = SafetyRepository(apiService);

    final result = await repository.submitReport(
      targetType: ReportTargetType.product,
      targetId: 'product-1',
      reason: 'misleading_listing',
      message: 'Wrong photo',
    );

    expect(result.isSuccess, isTrue);
    expect(apiService.lastPostEndpoint, ApiEndpoints.reports);
    expect(apiService.lastPostData, {
      'targetType': 'product',
      'targetId': 'product-1',
      'reason': 'misleading_listing',
      'message': 'Wrong photo',
    });
  });

  test('blocks users with the encoded user route', () async {
    final apiService = _RecordingApiService();
    final repository = SafetyRepository(apiService);

    final result = await repository.blockUser('seller 1');

    expect(result.isSuccess, isTrue);
    expect(apiService.lastPostEndpoint, '/api/blocks/seller%201');
    expect(apiService.lastPostData, isNull);
  });

  test('rejects invalid report input before calling the API', () async {
    final apiService = _RecordingApiService();
    final repository = SafetyRepository(apiService);

    final result = await repository.submitReport(
      targetType: ReportTargetType.user,
      targetId: '',
      reason: '',
    );

    expect(result.isSuccess, isFalse);
    expect(apiService.lastPostEndpoint, isNull);
  });
}
