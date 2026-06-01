class RepositoryWriteResult {
  final bool isSuccess;
  final String? errorCode;
  final String? message;
  final Object? error;

  const RepositoryWriteResult._({
    required this.isSuccess,
    this.errorCode,
    this.message,
    this.error,
  });

  factory RepositoryWriteResult.success() {
    return const RepositoryWriteResult._(isSuccess: true);
  }

  factory RepositoryWriteResult.failure({
    String? errorCode,
    String? message,
    Object? error,
  }) {
    return RepositoryWriteResult._(
      isSuccess: false,
      errorCode: errorCode,
      message: message,
      error: error,
    );
  }

  @override
  String toString() {
    if (isSuccess) return 'RepositoryWriteResult.success';
    return 'RepositoryWriteResult.failure('
        'errorCode: $errorCode, message: $message, error: $error)';
  }
}
