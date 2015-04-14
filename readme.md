# Grinder for Dart

A task based, dependency aware build system.

[![Build Status](https://travis-ci.org/google/grinder.dart.svg?branch=master)](https://travis-ci.org/google/grinder.dart)
[![Build status](https://ci.appveyor.com/api/projects/status/rxskyfnov8evqwib/branch/master?svg=true)](https://ci.appveyor.com/project/devoncarew/grinder-dart/branch/master)
[![Coverage Status](https://img.shields.io/coveralls/google/grinder.dart.svg)](https://coveralls.io/r/google/grinder.dart)

## Intro

Grinder is a library and tool to drive a command-line build.

Build files are entirely specified in Dart code. This allows you to write and
debug your build files with the same tools you use for the rest of your project
source.

## Installing

To install, run:

    pub global activate grinder

## Getting Started

Your grinder build file should reside at `tool/grind.dart`. You can use grinder
to create a simple, starting build script. To do this, run:

    pub global run grinder:init

This will create a starting script in `tool/grind.dart`.

In general, your build script will look something like this:

```dart
import 'package:grinder/grinder.dart';

main(args) => grind(args);

@Task('Initialize stuff.')
init() {
  log("Initializing stuff...");
}

@Task('Compile stuff.')
@Depends(init)
compile() {
  log("Compiling stuff...");
}

@DefaultTask('Deploy stuff.')
@Depends(compile)
deploy() {
  log("Deploying stuff...");
}
```

Tasks to run are specified on the command line. If a task has dependencies,
those dependent tasks are run before the specified task. Specifying no tasks on
the command-line will run the default task if one is configured.

## Command-line usage
    usage: grind <options> target1 target2 ...

    valid options:
    -h, --help    show targets but don't build
    -d, --deps    display the dependencies of targets

or:

    pub global run grinder <args>

will run the `tool/grind.dart` script with the supplied arguments. For for Dart
SDK 1.10.0, `pub run grinder` will also work.

## API documentation

Documentation is available [here](http://www.dartdocs.org/documentation/grinder/latest).

## Disclaimer

This is not an official Google product.
