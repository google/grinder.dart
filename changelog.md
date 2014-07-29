# grinder.dart changes

## 0.5.7
- added `runProcessAsync()` and related async methods (such as `PubTools.buildAsync(...)`)
- removed duplicated stack traces when the build fails with exceptions 
- throw an exception when running SDK binaries, and we are not able to locate the Dart SDK
