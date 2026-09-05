
import 'package:meta/meta.dart';

import 'effect.dart';
import 'types.dart';

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
@useResult
Iterable<E> co<E extends BaseEffect>(Computation<E> constructor) sync* {
  late void Function(Function setState) advance;
  // ignore: prefer_function_declarations_over_variables
  final BindState then = <T>(SetState<T> setState) => ((T received) {
    setState(received);
    advance(setState);
  }) as Continuation<T>;

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
class const MultipleResumeException._() implements Exception;

/// Exception thrown when [Effect.resume] is not called.
///
/// Technically not calling [Effect.resume] is _safe_
/// in the sense that the same [Effect] is yielded again and
/// again, until [Effect.resume] is called,
/// but that's really just an infinite loop.
class const NoResumeException._() implements Exception;