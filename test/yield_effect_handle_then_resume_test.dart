import 'package:test/test.dart';
import 'package:yield_effect_handle_then_resume/yield_effect_handle_then_resume.dart';

sealed class Effect extends BaseEffect {}

final class Print extends Effect {
  Print(this.message, this.success);

  final String message;

  @override
  final Continuation<void> success;
}

void main() {
  test("resume at most once", () {
    for (final effect in co((then) sync* {
      yield Print("hi", then((_) {}));
    })) {
      switch (effect) {
        case Print(:final message, success:final resume):
          print(message);
          resume(null);
          expect(() => resume(null), throwsA(isA<MultipleResumeException>()));
      }
    }
  });

  test("resume atleast once", () {
    var i = 0;

    expect(() {
      for (final effect in co((then) sync* {
        yield Print("hi", then((_) {}));
      })) {
        switch (effect) {
          default:
            print(i++);
            if (i > 10) throw Exception("let's not do an infinite loop :)");
        }
      }
    }, throwsA(isA<NoResumeException>()));
  });
}
