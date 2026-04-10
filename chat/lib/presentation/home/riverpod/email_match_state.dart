class EmailMatchState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  EmailMatchState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  EmailMatchState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return EmailMatchState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
