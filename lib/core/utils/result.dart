import 'package:equatable/equatable.dart';

abstract class Result<T> extends Equatable {
  const Result();
  
  bool get isSuccess => this is Success<T>;
  bool get isFailure => !isSuccess;
  
  T? get data => isSuccess ? (this as Success<T>).data : null;
  
  // Static factory methods for easier usage
  static Result<T> success<T>(T data) => Success(data);
  static Result<T> failure<T>(String message) => Failure(message);
}

class Success<T> extends Result<T> {
  @override
  final T data;
  
  const Success(this.data);
  
  @override
  List<Object?> get props => [data];
}

class Failure<T> extends Result<T> {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Extension methods for easy handling
extension ResultExtension<T> on Result<T> {
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else if (this is Failure<T>) {
      return failure((this as Failure<T>).message);
    } else {
      return failure('An error occurred');
    }
  }
  
  Result<R> map<R>(R Function(T data) mapper) {
    if (this is Success<T>) {
      try {
        return Success(mapper((this as Success<T>).data));
      } catch (e) {
        throw Exception('Error mapping result: $e');
      }
    } else {
      throw Exception('Cannot map failure result');
    }
  }
  
  Result<T> onFailure(Function(String message) handler) {
    if (isFailure) {
      handler('An error occurred');
    }
    return this;
  }
  
  Result<T> onSuccess(Function(T data) handler) {
    if (isSuccess) {
      handler(data ?? (throw Exception('Data is null')));
    }
    return this;
  }
}
