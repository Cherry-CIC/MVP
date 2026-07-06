import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/utils/result.dart';

class ForgotPasswordRepository {
  final FirebaseAuthService _authService;

  ForgotPasswordRepository(this._authService);

  Future<Result<void>> sendPasswordResetEmail(String email) async {
    return await _authService.sendPasswordResetEmail(email);
  }
}
