[![Dart](https://github.com/google/grinder.dart/actions/workflows/dart.yml/badge.svg)](https://github.com/google/grinder.dart/actions/workflows/dart.yml)
[![pub package](https://img.shields.io/pub/v/grinder.svg)](https://pub.dev/packages/grinder)

> Dart workflows, automated.

## What's this?

Grinder consists of a library to define project tasks (e.g. `test`, `build`,
`doc`) and a command-line tool to run them.

[![pub package](https://img.shields.io/pub/v/grinder.svg)](https://pub.dartlang.org/packages/grinder)
[![Build Status](https://github.com/google/grinder.dart/workflows/Dart/badge.svg)](https://github.com/google/grinder.dart/actions)

## Getting Started

To start using `grinder`, add it to your
[dev_dependencies](https://www.dartlang.org/tools/pub/dependencies.html#dev-dependencies).

### Defining Tasks

Tasks are defined entirely by Dart code allowing you to take advantage of
the whole Dart ecosystem to write and debug them.  Task definitions reside
in a `tool/grind.dart` script. To create a simple grinder script, run:

    pub run grinder:init

In general, grinder scripts look something like this:

```dart
import 'package:grinder/grinder.dart';

main(args) => grind(args);

@DefaultTask('Build the project.')
build() {
  log("Building...");
}

@Task('Test stuff.')
@Depends(build)
test() {
  new PubApp.local('test').run([]);
}

@Task('Generate docs.')
doc() {
  log("Generating docs...");
}

@Task('Deploy built app.')
@Depends(build, test, doc)
deploy() {
  ...
}
```

Any task dependencies (see `@Depends` above), are run before the dependent task.

Grinder contains a variety of convenience APIs for common task definitions, such
as `PubApp` referenced above.  See the
[API Documentation](https://pub.dev/documentation/grinder/latest/) for
full details.

### Running Tasks

First install the `grind` executable:

    pub global activate grinder

then use it to run desired tasks:

    grind test
    grind build doc

or to run a default task (see `@DefaultTask` above):

    grind

or to display a list of available tasks and their dependencies:

    grind -h

You can also bypass installing `grind` and instead use `pub run grinder`.

## Passing parameters to tasks

In order to pass parameters to tasks from the command-line, you query the
`TaskArgs` instance for your task invocation. For example:

`grind build --release --mode=topaz`

and:

```dart
@Task()
build() {
  TaskArgs args = context.invocation.arguments;
  bool isRelease = args.getFlag('release'); // will be set to true
  String mode = args.getOption('mode'); // will be set to topaz
  
  ...
}
```

would pass the flag `release` and the option `mode` to the `build` task.

You can pass flags and options to multiple tasks. The following command-line
would pass separate flags and options to two different tasks:

`grind build --release generate-docs --header=small`

## Disclaimer

This is not an official Google product.
