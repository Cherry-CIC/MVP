enum StatusType {
  uninitialized,  // Before any request is made
  loading,        // When a request is in progress
  success,        // When request completes successfully
  failure,        // When request fails
  canceled,       // If request was canceled
}

class Status {
  final StatusType type;
  final String? message;

  Status(this.type, {this.message = ''});

  static Status uninitialized = Status(StatusType.uninitialized);
  static Status loading = Status(StatusType.loading);
  static Status success = Status(StatusType.success);
  static Status canceled = Status(StatusType.canceled);

  static Status failure(String message) {
    return Status(StatusType.failure, message: message);
  }
}

