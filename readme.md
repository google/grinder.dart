# Grinder for Dart

A task based, dependency aware build system.

[![Build Status](https://drone.io/github.com/google/grinder.dart/status.png)](https://drone.io/github.com/google/grinder.dart/latest)

### Intro

A library and tool to drive a command-line build.

Grinder build files are entirely specified in Dart code. This allows you to
write and debug your build files with the same tools you use for the rest of
your project source.

Generally, a Grinder implementation will look something like this:

    void main([List<String> args]) {
      task('init', run: init);
      task('compile', run: compile, depends: ['init']);
      task('deploy', run: deploy, depends: ['compile']);
      task('docs', run: deploy, depends: ['init']);
      task('all', depends: ['deploy', 'docs']);

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

### API documentation

Documentation is available [here][docs].

## Disclaimer

This is not an official Google product.

[docs]: http://www.dartdocs.org/documentation/grinder/latest
