import 'package:yield_effect_handle_then_resume/yield_effect_handle_then_resume.dart';

final kevin = Friend(id: FriendId(0), name: "Kevin", birthday: DateTime(1995, 5, 26));
final bob = Friend(id: FriendId(1), name: "Bob", birthday: DateTime(2003, 2, 4));
final stuart = Friend(id: FriendId(2), name: "Stuart", birthday: DateTime(2000, 8, 16));
final alice = Friend(id: FriendId(3), name: "Alice", birthday: DateTime.now());
final myFriends = [bob, alice, stuart, kevin];

void main() {
  var i = 0;
  for (final effect in wishHappyBirthday) {
    print("${i++} current effect: $effect");
    switch (effect) {
      case GetInstant(:final resume):
        resume.call(DateTime.now());
      case GetFriend(:final friendId, :final resume):
        resume.call(myFriends.where((friend) => friend.id == friendId).first);
      case GetFriendsList(:final resume):
        resume.call(myFriends.map((friend) => friend.id).toList());
      case SendMessage(:final message, :final resume):
        print(message);
        resume.call(true);
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
      yield SendMessage(
        "Happy Birthday",
        then((confirmation) => print("Message sent to ${friend.name}: $confirmation")),
      ); // Retry handling left as an exercise to the reader
    }
  }
});

sealed class Effect extends BaseEffect {
  const Effect();
}

final class GetInstant extends Effect {
  const GetInstant(this.resume);

  @override
  final Continuation<DateTime> resume;
  @override
  set resume(Continuation<DateTime> _) {}
}

final class GetFriend extends Effect {
  const GetFriend(this.friendId, this.resume);

  final FriendId friendId;

  @override
  final Continuation<Friend> resume;
  @override
  set resume(Continuation<Friend> _) {}
}

typedef GetFriendsListFn = void Function(List<FriendId> friends);

final class GetFriendsList extends Effect {
  const GetFriendsList(this.resume);

  @override
  final GetFriendsListFn resume;
  @override
  set resume(GetFriendsListFn _) {}
}

typedef SendMessageFn = void Function(bool confirmation);

final class SendMessage extends Effect {
  const SendMessage(this.message, this.resume);

  final String message;

  @override
  final SendMessageFn resume;
  @override
  set resume(SendMessageFn _) {}
}

extension type FriendId(int id) {}

class Friend {
  const Friend({required this.id, required this.name, required this.birthday});

  final FriendId id;
  final String name;
  final DateTime birthday;
}
