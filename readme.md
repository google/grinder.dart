# Grinder for Dart

A task based, dependency aware build system.

[![Build Status](https://drone.io/github.com/google/grinder.dart/status.png)](https://drone.io/github.com/google/grinder.dart/latest)
[![Build Status](https://travis-ci.org/google/grinder.dart.svg?branch=master)](https://travis-ci.org/google/grinder.dart)

### Breaking changes!

Warning: lots of breaking changes in v0.6! Please see the [change log](https://github.com/google/grinder.dart/blob/master/changelog.md).

### Intro

Grinder is a library and tool to drive a command-line build.

Build files are entirely specified in Dart code. This allows you to
write and debug your build files with the same tools you use for the rest of
your project source.

### Getting Started

The build file for your application should reside at `tool/grinder.dart`.  A 
typical Grinder build file may look something like this:

    void main([List<String> args]) {
      task('init', init);
      task('compile', compile, ['init']);
      task('deploy', deploy, ['compile']);
      task('docs', deploy, ['init']);
      task('all', null, ['deploy', 'docs']);

      startGrinder(args);
    }

    init(GrinderContext context) {
      context.log("I set things up");
    }

    ...

Tasks to run are specified on the command line. If a task has dependencies,
those dependent tasks are run before the specified task.

### Command-line usage
    usage: dart grinder.dart <options> target1 target2 ...

    valid options:
    -h, --help    show targets but don't build
    -d, --deps    display the dependencies of targets

or:

    pub run grind <args>

will run the `tool/grinder.dart` script with the supplied arguments.

### API documentation

Documentation is available [here][docs].

### Disclaimer

This is not an official Google product.

[docs]: http://www.dartdocs.org/documentation/grinder/latest
