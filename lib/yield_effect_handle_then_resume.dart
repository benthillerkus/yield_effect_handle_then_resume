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
/// }
///
/// class AnotherEffect extends Effect {
///   AnotherEffect(this.message, this.resume);
///
///   final String message;
///
///   @override
///   final Continuation<void> resume;
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
/// as the [BaseEffect.success] function.
///
/// Inside the handler loop then you are iterating over the wrapped generator made with [co],
/// which passes through the [BaseEffect]s yielded by the inner generator.
///
/// When calling [BaseEffect.success] you are then effectively calling [Iterator.moveNext] on the inner generator,
/// which lets the outer generator yield the next [BaseEffect] or finish.
library;

export 'src/co.dart';
export 'src/effect.dart';
export 'src/fallible.dart';
export 'src/types.dart';
