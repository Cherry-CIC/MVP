class Result<T> {
  final T? value;
  final String? error;
  final bool isSuccess;
  final int? statusCode;
  final String? errorCode;

  Result.success(this.value, {this.statusCode}) : isSuccess = true, error = null, errorCode = null;
  Result.failure(this.error, {this.statusCode, this.errorCode}) : isSuccess = false, value = null;
}
