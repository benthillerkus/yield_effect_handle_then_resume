/// Using the received [T], update the locals inside your [Computation].
typedef SetState<T> = void Function(T arg);

/// Function that is called to resume the computation with a value of type [T].
typedef Continuation<T> = void Function(T received);

/// [Continuation] bound a function that advances the [Computation] to the next yield point.
typedef BindState = Continuation<T> Function<T>(SetState<T> callback);

/// Creates a coroutine that yields values of type [E] and can be resumed with values of type [T].
typedef Computation<E extends BaseEffect> =
    Iterable<E> Function(BindState then);

/// Wraps an [Iterable] of [BaseEffect]s so that it can only advance
/// to the next yield, when the [BaseEffect] has been handled.
/// 
/// ```dart
/// final doNothing = co((then) => sync* {
///   yield Noop(then((_){});
/// });
/// ```
/// 
/// ```dart
/// /// Probably looks just like this in the GitHub source code 🙃
/// final loadIssueComments = co((then) => sync* {
///   late final List<Comment> discussion;
///   yield GetDiscussion(issueId, pagination, then((list) => discussion = list));
///   if (Random.nextInt(10) < 9) { // 90% uptime 
///     yield Respond(discussion, then((_){}));
///   }
/// });
/// ```
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
    // TODO throw when the effect has not been handled
    yield iterator.current;
  }
}

/// Subclass your own effects as such
/// ```dart
/// /// Super class of all _your_ effects.
/// ///
/// /// Enables exhaustive pattern matching.
/// sealed class Effect extends BaseEffect {}
/// 
/// class GetUser extends Effect {
///   GetUser(this.id, this.resume);
///   
///   final int id;
/// 
///   @override
///   final Continuation<User> resume;
/// 
///   @override
///   // Either no-op or throw an error,
///   // you don't want to make this mutable.
///   set resume(Continuation<User> value) {}
/// }
/// ```
abstract class BaseEffect {
  /// Instance an effect with a [resume] function.
  /// 
  /// [resume] receives a value from the effect handler
  /// which should then be used to update local state.
  const BaseEffect();

  /// Continuation that is called by the effect handler
  ///  to continue the computation with the provided value.
  abstract covariant Continuation<Never> resume;
}
