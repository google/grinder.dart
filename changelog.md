# grinder.dart changes

## 0.7.0
- TODO:

## 0.6.5 (2015/1/13)
- added `defaultInit()` and `defaultClean()` methods, for common tasks
- added methods for Pub.global.activate and Pub.global.run
- added an optional `workingDirectory` argument to more methods
- added a `--version` command line flag
- have the version command check to see if there's a newer version of grinder
  available
- the dart2js compile tasks now create the output directory if it doesn't exist

## 0.6.4 (2014/12/18)
- clarify that users should put their build scripts in `tools/grind.dart`
- add a `getSdkDir` method

## 0.6.2 (2014/11/13)

- widen the version constraint on `quiver`

## 0.6.1 (2014/10/12)

- widen the version constraint on `args`

## 0.6.0 (2014/09/22)

The convenience API is now more terse:
- the `defineTask()` method has been renamed to `task()`
- instead of named parameters, the `task()` function now uses optional
  positional parameters

Added two new entrypoint files in `bin/`: `grind.dart` and `grinder.dart`. These
let you run grinder via:

    pub run grinder test

They look for a corresponding grinder script in the `tool` directory
(`bin/grind.dart` looks for `tool/grind.dart` and `bin/grinder.dart` looks for
`tool/grinder.dart`). If they find a corresponding script they run it in a new
Dart VM process. This means that projects will no longer have to have a
`grind.sh` script in the root of each project.

PubTool's build methods now take an optional `workingDirectory` argument.

Removed `runSdkBinary` and `runSdkBinaryAsync`, and they are no longer needed.
Use `runProcess` and `runProcessAsync` instead.

The methods on `PubTools` and `Dart2jsTools` are now static - you no longer need
to create an instance to use them. Also, `PubTools` was renamed to `Pub` and
`Dart2jsTools` was renamed to `Dart2js`. And a new utility class for
dartanalyzer - `Analyzer` - was created.

## 0.5.7 (2014/07/28)

- added `runProcessAsync()` and related async methods (such as
  `PubTools.buildAsync(...)`)
- removed duplicated stack traces when the build fails with exceptions
- throw an exception when running SDK binaries, and we are not able to locate
  the Dart SDK
