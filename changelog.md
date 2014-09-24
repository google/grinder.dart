# grinder.dart changes

## 0.6.0 (2014/09/22)

The convenience API is now more terse:
- the `defineTask()` method has been renamed to `task()`
- instead of named parameters, the `task()` function now uses optional positional parameters

Added two new entrypoint files in `bin/`: `grind.dart` and `grinder.dart`. These
let you run grinder via:

    pub run grinder test

They look for a cooresponding grinder script in the `tool` directory (`bin/grind.dart`
looks for `tool/grind.dart` and `bin/grinder.dart` looks for `tool/grinder.dart`).
If they find a cooresponding script they run it in a new Dart VM process. This
means that projects will no longer have to have a `grind.sh` script in the root
of each project.

PubTool's build methods now take an optional `workingDirectory` argument.

Removed `runSdkBinary` and `runSdkBinaryAsync`, and they are no longer needed.
Use `runProcess` and `runProcessAsync` instead.

## 0.5.7 (2014/07/28)

- added `runProcessAsync()` and related async methods (such as `PubTools.buildAsync(...)`)
- removed duplicated stack traces when the build fails with exceptions
- throw an exception when running SDK binaries, and we are not able to locate the Dart SDK
