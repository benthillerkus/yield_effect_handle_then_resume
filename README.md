_yield effect, handle, then resume_

<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/tools/pub/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

Tiny library for writing effect handlers and typed continuations.

# whatwhy

Effects can be understood as the things a function _does_ besides just returning a value.

For example writing to a file could be an effect, or accepting input or throwing an Exception.

Sometimes you want your Function to be generic over an effect.

For example, maybe you're writing an API client and you want to support
both sync and async*, without having to implement the auth flow twice.

Or you've written a program that makes use of GPIO pins, and now want to write tests that can run without you having to fiddle with the hardware.

In both cases, you could have your function yield an effect when it needs to do IO, and let the caller handle those effects as appropriate.

Such an effect handler could be as simple as

```dart
for (final effect in ytDownloader) {
    switch (effect) {
        case WriteDisk(:final file, :final resume):
            final success = write(file); // For illustrative purposes
            resume.call(success);
        case DownloadSong(title: "Never Gonna Give You Up", :final resume):
            resume.call(File("rick.mp4"));
        ...
    }
}
```

This is a form of dependency inversion and this style of programming is also called [sans-io](https://www.firezone.dev/blog/sans-io).

Rewriting a typical computation (method) with a bunch of control flow and other effects into this style
would normally require you to hand-write a large and unwieldy state-machine.

Thankfully Dart does this already for us when we write sync* (and async*) generators.
Missing only is really the ability to continue with a value.

The only thing this library then does is provide some wrappers that only advance
the computation when `resume` has been called and a `BaseEffect` type,
through which you can can enjoy full type safety in the effect handler,
and inside the implementation of your computation.

## Getting started

```
dart pub add yield_effect_handle_then_resume
```

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

I've written this with the goal to refactor my [Db Migrations with Multiverse Time Travel](https://github.com/benthillerkus/db_migrations_with_multiverse_time_travel) packge to be sync / async agnostic.

This is 100% slop free, hand-made, ethically sourced etc. and all mistakes are of my own.

I did afterwards ask Gemini to help me with the naming of some types to be correct with FP literature and the results where ... mixed. So if here's something that claims to be something it's not, please do tell; I'd gladly correct it.
