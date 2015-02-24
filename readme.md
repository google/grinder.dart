# Grinder for Dart

A task based, dependency aware build system.

[![Build Status](https://travis-ci.org/google/grinder.dart.svg?branch=master)](https://travis-ci.org/google/grinder.dart)
[![Coverage Status](https://img.shields.io/coveralls/google/grinder.dart.svg)](https://coveralls.io/r/google/grinder.dart)

## Intro

Grinder is a library and tool to drive a command-line build.

Build files are entirely specified in Dart code. This allows you to write and
debug your build files with the same tools you use for the rest of your project
source.

## Getting Started

Your grinder build file should reside at `tool/grind.dart`, and may look
something like:

```dart
import 'package:grinder/grinder.dart';

const main = grind;

@Task(
    description: 'Initialize stuff.')
init(GrinderContext context) {
  context.log("Initializing stuff...");
}

@Task(
    depends: const ['init'],
    description: 'Compile stuff.')
compile(GrinderContext context) {
  context.log("Compiling stuff...");
}

@Task(
    depends: const ['compile'],
    description: 'Deploy stuff.')
deploy(GrinderContext context) {
  context.log("Deploying stuff...");
}

@Task(
    name: 'default',
    depends: const ['deploy'])
_default(GrinderContext context) {}
```

Tasks to run are specified on the command line. If a task has dependencies,
those dependent tasks are run before the specified task.

Specifying no tasks on the command-line is equivalent to specifying the 
`default` task.

## Installing

To install, run:

    pub global activate grinder

## Command-line usage
    usage: dart grind.dart <options> target1 target2 ...

    valid options:
    -h, --help    show targets but don't build
    -d, --deps    display the dependencies of targets

or:

    pub global run grind <args>

will run the `tool/grind.dart` script with the supplied arguments.

## API documentation

Documentation is available [here](http://www.dartdocs.org/documentation/grinder/latest).

## Disclaimer

This is not an official Google product.
