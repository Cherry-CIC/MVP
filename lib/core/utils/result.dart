class Result<T> {
  final T? value;
  final String? error;
  final bool isSuccess;
  final int? statusCode;

  Result.success(this.value) : isSuccess = true, error = null, statusCode = null;
  Result.failure(this.error, {this.statusCode}) : isSuccess = false, value = null;
}
