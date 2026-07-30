import 'package:cherry_mvp/core/services/network/api_service.dart';

class UnexpectedApiService implements ApiService {
  const UnexpectedApiService();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected API request: ${invocation.memberName}');
  }
}
