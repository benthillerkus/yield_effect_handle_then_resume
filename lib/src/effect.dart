
import 'package:meta/meta.dart';

import 'types.dart';

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
/// }
/// ```
abstract class BaseEffect {
  /// When constructing a [BaseEffect], always pass
  /// `then((value) => ...)` as the [success] function
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
  /// case MyEffect():
  ///   continue;
  ///
  /// // ok
  /// case InsertDisk(: final diskNr):
  ///   print("Please insert disk $diskNr");
  ///   io.openTray();
  ///   await io.trayClosed();
  ///   final content = io.read();
  ///   effect.success(content);
  ///
  /// // not ok
  /// case GetInput():
  ///   effect.success("hi");
  ///   effect.success("hello");
  /// ```
  ///
  /// See [MultipleResumeException], [NoResumeException]
  @doNotStore
  @mustBeOverridden
  abstract final Continuation<Never> success;
}


