import 'dart:math';

import 'package:yield_effect_handle_then_resume/yield_effect_handle_then_resume.dart';

final kevin = Friend(id: FriendId(0), name: "Kevin", birthday: DateTime(1995, 5, 26));
final bob = Friend(id: FriendId(1), name: "Bob", birthday: DateTime(2003, 2, 4));
final stuart = Friend(id: FriendId(2), name: "Stuart", birthday: DateTime(2000, 8, 16));
final alice = Friend(id: FriendId(3), name: "Alice", birthday: DateTime.now());
final myFriends = [bob, alice, stuart, kevin];

void main() {
  var i = 0;
  final random = Random();
  for (final effect in wishHappyBirthday) {
    print("${i++} current effect: $effect");
    switch (effect) {
      case GetInstant():
        effect.success(DateTime.now());
      case GetFriend(:final friendId):
        effect.success(myFriends.where((friend) => friend.id == friendId).first);
      case GetFriendsList():
        effect.success(myFriends.map((friend) => friend.id).toList());
      case SendMessage(:final message):
        if (random.nextDouble() < .3) {
          print(message);
          effect.success(null);
        } else {
          effect.failure(Exception("Failed to send message"));
        }
      case Wait():
        // await Future.delayed(duration);
        effect.success(null);
    }
  }
}

final wishHappyBirthday = co<Effect>((then) sync* {
  late DateTime today;
  yield GetInstant(then((instant) => today = instant));

  late List<FriendId> friends;
  yield GetFriendsList(then((list) => friends = list));

  for (final id in friends) {
    late Friend friend;
    yield GetFriend(id, then((data) => friend = data));

    if (friend.birthday.day == today.day && friend.birthday.month == today.month) {
      yield* then.retry<Effect, Exception>(
        (attempt, error, [stackTrace]) sync* {
          if (attempt > 5) throw error;
          final random = Random();
          var delay = Duration(milliseconds: 100 * pow(2, attempt).ceil());
          final jitter = Duration(milliseconds: random.nextInt(delay.inMilliseconds ~/ 2));
          delay = delay ~/2 + jitter;
          yield Wait(delay, then((_) => print("Retrying to send message to ${friend.name} in $delay")));
        },
        (onError) => SendMessage(
          "Happy Birthday",
          then((_) => print("Message successfully sent to ${friend.name}")),
          onError,
        ),
      );
    }
  }
});

sealed class const Effect() extends BaseEffect;

final class const GetInstant(this.success) extends Effect {
  @override
  final Continuation<DateTime> success;
}

final class const GetFriend(this.friendId, this.success) extends Effect {
  final FriendId friendId;

  @override
  final Continuation<Friend> success;
}

final class const GetFriendsList(this.success) extends Effect {
  @override
  final Continuation<List<FriendId>> success;
}

final class const SendMessage(this.message, this.success, this.failure)
    extends Effect
    with Fallible<Exception> {
  final String message;

  @override
  final Continuation<void> success;

  @override
  final ContinuationFailure<Exception> failure;
}

final class const Wait(this.duration, this.success) extends Effect {
  final Duration duration;

  @override
  final Continuation<void> success;
}

extension type FriendId(int id);

class const Friend({
  required final FriendId id,
  required final String name,
  required final DateTime birthday,
});
