class Result<T> {
  final T? value;
  final String? error;
  final bool isSuccess;

  Result.success(this.value) : isSuccess = true, error = null;
  Result.failure(this.error) : isSuccess = false, value = null;
}