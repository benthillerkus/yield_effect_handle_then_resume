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
  late void Function(Function setState) advance;
  // ignore: prefer_function_declarations_over_variables
  final BindState then = <T>(SetState<T> setState) =>
      ((T received) {
            advance(setState);
            setState(received);
          })
          as Continuation<T>;

  final iterator = constructor(then).iterator;
  var movedNext = iterator.moveNext();

  /// Is compared with [setState] in [advance] to prevent
  /// the same [setState] being called more than once,
  /// which indicates that [Effect.resume] was called more than once.
  /// 
  /// See [MultipleResumeException]
  Function? lastSetState;

  /// Flips each time an element of this [Iterable] is consumed
  bool ping = false;
  /// Flips each time [Effect.resume] is called.
  bool pong = true;
  advance = (setState) {
    if (identical(lastSetState, setState)) throw const MultipleResumeException._();
    lastSetState = setState;
    pong = !pong;
    movedNext = iterator.moveNext();
  };
  while (movedNext) {
    if (ping == pong) throw NoResumeException._();
    yield iterator.current;
    ping = !ping;
  }
}

/// Exception thrown when [Effect.resume] is called more than once.
/// 
/// In some programming languages this is actually a feature, which is really cool,
/// but it's not really possible to emulate this in Dart.
/// Everything I can think of would more or less
/// be just programming in continuation-passing style.
class MultipleResumeException implements Exception {
  const MultipleResumeException._();
}

/// Exception thrown when [Effect.resume] is never called.
/// 
/// Technically not a problem, since the same [Effect]
/// will just be yielded again, until it is handled.
/// 
/// But since that then most likely just ends up
/// being an infinite loop, this exception is
/// thrown in as a wrench. 
class NoResumeException implements Exception {
  const NoResumeException._();
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
  /// [resume] sends a value from the effect handler
  /// to the [Computation] which can then update local state.
  /// 
  /// The [Continuation] passed into this should be defined adhoc,
  /// inside the [BaseEffect.new] constructor, because
  /// reusing the same [Continuation] on multiple effects
  /// will trigger the [MultipleResumeException] as a guard
  /// against calling [resume] more than once.
  /// 
  /// ```
  /// // ok
  /// yield MyEffect(then((value) => doSomething(value)));
  /// 
  /// // also ok
  /// yield AnotherEffect((then(_) {}));
  /// 
  /// // not ok
  /// var counter = 0;
  /// final cont = then(() => counter++);
  /// 
  /// yield MyEffect(cont);
  /// yield MyEffect(cont);
  /// ```
  const BaseEffect();

  /// Continuation that is called by the effect handler
  /// to continue the computation with the provided value.
  /// 
  /// Call this exactly **once** when _handling_ the effect.
  /// 
  /// ```dart
  /// // not ok
  /// case MyEffect(: final resume):
  ///   continue;
  /// 
  /// // ok
  /// case InsertDisk(: final diskNr, : final resume):
  ///   print("Please insert disk $diskNr");
  ///   io.openTray();
  ///   await io.trayClosed();
  ///   final content = io.read();
  ///   resume(content);
  /// 
  /// // not ok
  /// case GetInput(: final resume):
  ///   resume("hi");
  ///   resume("hello");
  /// ```
  /// 
  /// See [MultipleResumeException], [NoResumeException]
  abstract covariant Continuation<Never> resume;
}
