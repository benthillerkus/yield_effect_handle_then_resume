import 'package:meta/meta.dart';

import 'effect.dart';
import 'types.dart';

mixin Fallible<E> on BaseEffect {
  @doNotStore
  @mustBeOverridden
  abstract final ContinuationFailure<E> failure;
}

extension ThenErrorExt on BindState {
  ContinuationFailure<E> error<E>(void Function(E error, [StackTrace? stackTrace]) onError) {
    final bound = this(((E, StackTrace?) tup) => onError(tup.$1, tup.$2));
    return (E error, [StackTrace? stackTrace]) => bound((error, stackTrace));
  }

  Iterable<X> retry<X extends BaseEffect, E>(
    Iterable<X> Function(int attempt, E error, [StackTrace? stackTrace]) onRetry,
    X Function(ContinuationFailure<E> onError) effect,
  ) sync* {
    int attempt = 0;
    bool needsRetry;
    Iterable<X>? extra;
    do {
      needsRetry = false;
      extra = null;
      yield effect(
        error((error, [stackTrace]) {
          needsRetry = true;
          attempt += 1;
          extra = onRetry(attempt, error, stackTrace);
        }),
      );
      if (extra != null) yield* extra!;
    } while (needsRetry);
  }
}
