import 'failure.dart';

/// Sealed functional Result type for error handling without throws.
sealed class Result<S, F extends Failure> {
  const Result();

  bool get isSuccess => this is Success<S, F>;
  bool get isFailure => this is ErrorResult<S, F>;
  bool get isError => isFailure;

  S? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        ErrorResult() => null,
      };

  F? get failureOrNull => switch (this) {
        Success() => null,
        ErrorResult(failure: final f) => f,
      };

  R fold<R>(R Function(S data) onSuccess, R Function(F failure) onFailure) {
    return switch (this) {
      Success(data: final d) => onSuccess(d),
      ErrorResult(failure: final f) => onFailure(f),
    };
  }

  Result<T, F> map<T>(T Function(S data) transform) {
    return switch (this) {
      Success(data: final d) => Success(transform(d)),
      ErrorResult(failure: final f) => ErrorResult(f),
    };
  }
}

final class Success<S, F extends Failure> extends Result<S, F> {
  final S data;
  const Success(this.data);
}

final class ErrorResult<S, F extends Failure> extends Result<S, F> {
  final F failure;
  const ErrorResult(this.failure);
}
