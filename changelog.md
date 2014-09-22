# grinder.dart changes

## 0.6.0 (2014/09/22)

The convenience API is now more terse:
- the `defineTask()` method has been renamed to `task()`
- instead of named parameters, it now uses optional positional parameters

## 0.5.7 (2014/07/28)

- added `runProcessAsync()` and related async methods (such as `PubTools.buildAsync(...)`)
- removed duplicated stack traces when the build fails with exceptions
- throw an exception when running SDK binaries, and we are not able to locate the Dart SDK
