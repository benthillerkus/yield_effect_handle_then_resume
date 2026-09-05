import 'effect.dart';

/// Update the locals inside your [Computation] using the [T] that was passed to [Effect.resume].
///
/// Runs before the [Computation] continues from the yield point.
typedef SetState<T> = void Function(T arg);

/// Passes a value back to the [Computation] and then resumes it from the yield point.
///
/// Passed into a [BaseEffect] constructor as the [BaseEffect.success] function.
typedef Continuation<T> = void Function(T received);

typedef ContinuationFailure<E> = void Function(E error, [StackTrace? stackTrace]);

/// _Binds_ a [SetState] callback to a [Continuation] that will be called as [BaseEffect.success].
typedef BindState = Continuation<T> Function<T>(SetState<T> callback);

/// Creates an [Iterable] that must be resumed by calling [E.resume] before it yields the next [E].
typedef Computation<E extends BaseEffect> = Iterable<E> Function(BindState then);
