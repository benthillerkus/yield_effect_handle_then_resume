// ignore_for_file: public_member_api_docs

typedef SetState<T> = void Function(T arg);

/// Function that is called to resume the computation with a value of type [T].
typedef Continuation<T> = void Function(T received);

/// [Continuation] bound a function that advances the [Computation] to the next yield point.
typedef BindState = Continuation<T> Function<T>(SetState<T> callback);

/// Creates a coroutine that yields values of type [E] and can be resumed with values of type [T].
typedef Computation<E extends BaseEffect> =
    Iterable<E> Function(BindState receive);

Iterable<E> co<E extends BaseEffect>(Computation<E> constructor) sync* {
  late void Function(void _) advance;
  // ignore: prefer_function_declarations_over_variables
  final BindState then = <T>(SetState<T> setState) =>
      ((T received) {
            setState(received);
            advance(null);
          })
          as Continuation<T>;

  final iterator = constructor(then).iterator;
  var movedNext = iterator.moveNext();
  advance = (_) => movedNext = iterator.moveNext();
  while (movedNext) {
    yield iterator.current;
  }
}

abstract class BaseEffect {
  const BaseEffect();

  abstract covariant Continuation<Never> resume;
}
