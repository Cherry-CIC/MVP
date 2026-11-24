import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/products/safety_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingApiService implements ApiService {
  String? lastPostEndpoint;
  dynamic lastPostData;
  String? lastGetEndpoint;
  Result<dynamic> nextGetResult = Result.success(const {
    'success': true,
    'data': {
      'blocks': [
        {'id': 'b1', 'blockerId': 'viewer-1', 'blockedUserId': ' seller-1 '},
        {'id': 'b2', 'blockerId': 'viewer-1', 'blockedUserId': 'seller-2'},
        {'id': 'b3', 'blockerId': 'viewer-1', 'blockedUserId': '   '},
      ],
    },
  });

  @override
  Future<Result<T>> get<T>(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    lastGetEndpoint = endpoint;
    final result = nextGetResult;
    if (!result.isSuccess) {
      return Result.failure(result.error, statusCode: result.statusCode);
    }
    return Result.success(result.value as T, statusCode: result.statusCode);
  }

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

  test('submits charity reports with targetType charity', () async {
    final apiService = _RecordingApiService();
    final repository = SafetyRepository(apiService);

    final result = await repository.submitReport(
      targetType: ReportTargetType.charity,
      targetId: 'dogs-trust',
      reason: 'misleading_information',
      message: 'Outdated mission details',
    );

    expect(result.isSuccess, isTrue);
    expect(apiService.lastPostEndpoint, ApiEndpoints.reports);
    expect(apiService.lastPostData, {
      'targetType': 'charity',
      'targetId': 'dogs-trust',
      'reason': 'misleading_information',
      'message': 'Outdated mission details',
    });
  });

  test('blocks charities with the encoded charity block route', () async {
    final apiService = _RecordingApiService();
    final repository = SafetyRepository(apiService);

    final result = await repository.blockCharity('dogs trust');

    expect(result.isSuccess, isTrue);
    expect(apiService.lastPostEndpoint, '/api/blocks/charities/dogs%20trust');
    expect(apiService.lastPostData, isNull);
  });

  test('rejects unsafe charity identifiers before calling block endpoint', () async {
    final apiService = _RecordingApiService();
    final repository = SafetyRepository(apiService);

    for (final invalidId in ['', '  ', '.', '..', 'dogs/trust']) {
      final result = await repository.blockCharity(invalidId);
      expect(result.isSuccess, isFalse);
      expect(apiService.lastPostEndpoint, isNull);
    }
  });

  test('fetches and normalizes blocked user IDs from /api/blocks', () async {
    final apiService = _RecordingApiService();
    final repository = SafetyRepository(apiService);

    final result = await repository.fetchBlockedUsers();

    expect(result.isSuccess, isTrue);
    expect(apiService.lastGetEndpoint, ApiEndpoints.blocks);
    expect(result.value, {'seller-1', 'seller-2'});
  });

  test('returns failure when fetching blocked users fails or payload is invalid', () async {
    final apiService = _RecordingApiService()..nextGetResult = Result.failure('Network error', statusCode: 500);
    final repository = SafetyRepository(apiService);

    final failed = await repository.fetchBlockedUsers();
    expect(failed.isSuccess, isFalse);

    apiService.nextGetResult = Result.success(const {'success': false});
    final unsuccessful = await repository.fetchBlockedUsers();
    expect(unsuccessful.isSuccess, isFalse);
  });
}
