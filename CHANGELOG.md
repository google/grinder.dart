# grinder.dart changes

## 0.8.1
- Added the ability to pass task functions parameters from the command line via
  a `TaskArgs` object
- Removed support for task functions taking a `GrinderContext` parameter
- Remove a dependency on a non-strong mode package (`unscripted`)

## 0.8.0+3
- All APIs, including `pub run grinder`, always use the same Dart version as the
  user.

## 0.8.0+2
- Added `categories` and `extraArgs` parameters to `Dart2Js.compile()` and
  `Dart2Js.compileAsync()`

## 0.8.0+1 (2015/11/12)
- Fixed a bug with the DDC `--html-report` option

## 0.8.0 (2015/10/29)
- Removed deprecated constants: BIN_DIR, BUILD_DIR, LIB_DIR, WEB_DIR
- Removed the 120-col line wrapping on task output
- Added a task for DDC (dev_compiler)
- Fixed an issue where we were emitting overly verbose stack traces on failures
- Fixed an issue where we would emit stdout after a failure, even when the stdout
  had been emitted as part of the task
- Added `outFile` and `enableExperimentalMirrors` to the dart2js task
- Some grinder output now written using ansi colors
- Removed the deprecated `defaultInit` method.
- Added a task for dartdoc
- Added a new `sdkBin()` method

## 0.7.2 (2015/7/8)
- Auto-expand directories passed to `Analyzer.analyze()` to a list of Dart
  source files using the added method `findDartSourceFiles()`.
- Add tests for `Analyzer.analyze()` task.
- Add `sourceDirs` and `existingSourceDirs` to return the projects top-level
  directories usually containing Dart source files.
- Deprecate the `Tests` class (in favor of `TestRunner`)
- Add `lineLength` as an optional argument to `DartFmt.format`

## 0.7.1+3 (2015/5/24)
- Fix bug with Dart.run/runAsync. Args were swapped.

## 0.7.1+2 (2015/5/24)
- Add a `Dart.runAsync` static method.

## 0.7.1+1 (2015/5/19)
- Add a `files` param to `TestRunner.test`.

## 0.7.1 (2015/5/19)
- Added `grind --completion install` command to install tab-completion for task names
  and options in `grind`.
- Improved `grind -h` (help) output.
- `Dart.run` now takes an optional `vmArgs`, a list of arguments passed to the Dart VM.
- Added `downgrade` method do `Pub`.
- Introduce `RunOptions` to support all `Process.run`/`Process.start`
  parameters. The `workingDirectory` parameter is now deprecated in all methods,
  use `RunOptions.workingDirectory` instead.
- Added `PubApp.runAsync`.
- In `Dart.run`, deprecate the vmNewGenHeapMB and vmOldGenHeapMB options.
- Added support for passing lists of files or directories to `DartFmt.format()`.
- `Analyzer.analyzeFiles` is deprecated in favor of `Analyzer.analyze`.
- Added a `Pub.global.list()` method to list the installed applications.
- added a `TestRunner` class - a wrapper around the new `test` package.

## 0.7.0 (2015/4/20)
- Big changes! Task definitions are now primarily annotation based; see the
  [readme](https://github.com/google/grinder.dart) for more information and an example
- The `GrinderContext` arg is no longer expected in task functions. Instead, the
  `context` variable (and the `log` and `fail` functions) are available as global
  variables. They're injected into the zone running the current task.
- `pub [global] run grinder:grind` no longer work, use
  `pub [global] run grinder` instead.  Add `:grinder` if using `pub run` in Dart SDK < 1.10.
- `copyFile` and `copyDirectory` and deprecated in favor of a new `copy` method
- `deleteEntity` is deprecated in favor of a new `delete` method
- Renamed `runProcess`/`runProcessAsync`/`runDartScript` to `run`/`runAsync`/`Dart.run`.
  Process result info (stdout, stderr, exitCode) is now exposed by these
  methods and some others which call them.
- Added a wrapper class around `pub global activate/run`/`pub run` applications - `PubApp`
- Grinder can now create a simple starter script for a project - run `pub run grinder:init`

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
