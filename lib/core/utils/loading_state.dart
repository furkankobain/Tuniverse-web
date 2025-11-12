import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadingState extends Equatable {
  final bool isLoading;
  final String? message;
  
  const LoadingState({
    this.isLoading = false,
    this.message,
  });
  
  const LoadingState.loading({String? message}) : this(isLoading: true, message: message);
  const LoadingState.loaded() : this(isLoading: false);
  const LoadingState.error(String message) : this(isLoading: false, message: message);
  
  LoadingState copyWith({
    bool? isLoading,
    String? message,
  }) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
    );
  }
  
  @override
  List<Object?> get props => [isLoading, message];
}

// Loading State Provider

final globalLoadingProvider = StateProvider<LoadingState>((ref) {
  return const LoadingState.loaded();
});

// Helper functions for managing loading state
extension LoadingStateExtension on WidgetRef {
  void setLoading({String? message}) {
    read(globalLoadingProvider.notifier).state = LoadingState.loading(message: message);
  }
  
  void setLoaded() {
    read(globalLoadingProvider.notifier).state = const LoadingState.loaded();
  }
  
  void setError(String message) {
    read(globalLoadingProvider.notifier).state = LoadingState.error(message);
  }
}
