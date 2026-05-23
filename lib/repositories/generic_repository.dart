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

  const RepositoryWriteResult.success()
      : this._(isSuccess: true);

  const RepositoryWriteResult.failure({
    String? errorCode,
    String? message,
    Object? error,
  }) : this._(
          isSuccess: false,
          errorCode: errorCode,
          message: message,
          error: error,
        );
}
