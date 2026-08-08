/// # Usage
///
/// To make use of this library, you write an effect handler, which can look like this:
/// ```dart
/// // drive the computation to the next yield
/// for (final effect in computation) {
/// // handle the effect
///   switch (effect) {
///     case MyEffect(: final resume):
///       // do something with effect
///       print("My effect");
///       // resume after handling the effect
///       resume(value);
///     case AnotherEffect(: final message, : final resume):
///       print("Another effect: ${message}");
///       resume(null);
///   }
/// }
/// ```
///
/// `computation` is an [Iterable] of [BaseEffect]s, which you can create using the [co] function:
///
/// ```dart
/// final computation = co((then) => sync* {
///   // if you want to receive a value from the effect handler,
///   // first declare a place to store it...
///   late var myState;
///   // and then assign it inside the [then] callback,
///   // which will run, before the [Computation] continues from the yield point.
///   yield MyEffect(then((value) => myState = value));
///   // so by the time doSomethingWith is called, myState has been assigned.
///   doSomethingWith(myState);
///
///   // if you don't need to receive a value, just pass an empty callback to [then]
///   yield AnotherEffect("Hello, world!", then((_) {}));
/// });
/// ```
///
/// Finally each of the effects need to be defined as a subclass of [BaseEffect], which can look like this:
/// ```dart
/// sealed class Effect extends BaseEffect {}
/// class MyEffect extends Effect {
///   MyEffect(this.message, this.resume);
///   final String message;
///   @override
///   final Continuation<String> resume;
///
///   @override
///   // make sure the setter cannot be used to change the resume function
///   set resume(Continuation<String> value) {}
/// }
///
/// class AnotherEffect extends Effect {
///   AnotherEffect(this.message, this.resume);
///
///   final String message;
///
///   @override
///   final Continuation<void> resume;
///   @override
///   set resume(Continuation<void> value) {}
/// }
/// ```
///
/// # Explanation
///
/// Dart generators like `sync*` already allow you to return (yield) multiple times from the same function,
/// and also to pause and resume the function at each yield point.
///
/// This library makes use of that to additionally allow you to pass values back into the generator.
///
/// This is achieved by wrapping the (inner) generator with [co].
///
/// Internally, [co] creates an [Iterator] from the generator, and passes the [Iterator.moveNext]
/// back into the generator.
///
/// The generator _then_ yields instances of [BaseEffect] which have been initialized with the [Iterator.moveNext] function
/// as the [BaseEffect.resume] function.
///
/// Inside the handler loop then you are iterating over the wrapped generator made with [co],
/// which passes through the [BaseEffect]s yielded by the inner generator.
///
/// When calling [BaseEffect.resume] you are then effectively calling [Iterator.moveNext] on the inner generator,
/// which lets the outer generator yield the next [BaseEffect] or finish.
library;

/// Update the locals inside your [Computation] using the [T] that was passed to [Effect.resume].
///
/// Runs before the [Computation] continues from the yield point.
typedef SetState<T> = void Function(T arg);

/// Passes a value back to the [Computation] and then resumes it from the yield point.
///
/// Passed into a [BaseEffect] constructor as the [BaseEffect.resume] function.
typedef Continuation<T> = void Function(T received);

/// _Binds_ a [SetState] callback to a [Continuation] that will be called as [BaseEffect.resume].
typedef BindState = Continuation<T> Function<T>(SetState<T> callback);

/// Creates an [Iterable] that must be resumed by calling [E.resume] before it yields the next [E].
typedef Computation<E extends BaseEffect> = Iterable<E> Function(BindState then);

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
class MultipleResumeException implements Exception {
  const MultipleResumeException._();
}

/// Exception thrown when [Effect.resume] is not called.
///
/// Technically not calling [Effect.resume] is _safe_
/// in the sense that the same [Effect] is yielded again and
/// again, until [Effect.resume] is called,
/// but that's really just an infinite loop.
class NoResumeException implements Exception {
  const NoResumeException._();
}

/// Subclass your own effects as such
/// ```dart
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
///   // Either no-op or throw an error;
///   // just make sure [resume] cannot be changed.
///   set resume(Continuation<User> value) {}
/// }
/// ```
abstract class BaseEffect {
  /// When constructing a [BaseEffect], always pass
  /// `then((value) => ...)` as the [resume] function
  /// into the constructor.
  ///
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
  ///
  /// See [MultipleResumeException], [NoResumeException].
  const BaseEffect();

  /// Passes a value back to the [Computation] that yielded this [BaseEffect].
  ///
  /// The [Computation] will then continue executing
  /// until it yields the next [BaseEffect] or finishes.
  ///
  /// Must be called exactly once.
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
