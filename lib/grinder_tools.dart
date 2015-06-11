// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/// Commonly used tools for build scripts.
library grinder.tools;

import 'dart:async';
import 'dart:io';

import 'grinder.dart';
import 'src/run.dart' as run_lib;
import 'src/run_utils.dart';
import 'src/utils.dart';

export 'src/run.dart';

final Directory binDir = new Directory('bin');
final Directory buildDir = new Directory('build');
final Directory libDir = new Directory('lib');
final Directory webDir = new Directory('web');

@Deprecated('See binDir') Directory get BIN_DIR => binDir;
@Deprecated('See buildDir') Directory get BUILD_DIR => buildDir;
@Deprecated('See libDir') Directory get LIB_DIR => libDir;
@Deprecated('See webDir') Directory get WEB_DIR => webDir;

/// Run a dart [script] using [run_lib.run].
///
/// Returns the stdout.
@Deprecated('Use `Dart.run` instead.')
String runDartScript(String script, {List<String> arguments: const [],
    bool quiet: false, String packageRoot, RunOptions runOptions,
    @deprecated int vmNewGenHeapMB, //
    @deprecated int vmOldGenHeapMB, //
    @Deprecated('see RunOptions.workingDirectory') String workingDirectory}) {
  runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
  return Dart.run(script,
      arguments: arguments,
      quiet: quiet,
      packageRoot: packageRoot,
      runOptions: runOptions,
      vmNewGenHeapMB: vmNewGenHeapMB,
      vmOldGenHeapMB: vmOldGenHeapMB);
}

/// A default implementation of an `init` task. This task verifies that the
/// grind script is executed from the project root.
@Deprecated(
    'the functionality of this method has been rolled into grinder startup')
void defaultInit([GrinderContext context]) {}

/// A default implementation of a `clean` task. This task deletes all generated
/// artifacts in the `build/`.
void defaultClean([GrinderContext context]) => delete(buildDir);

/// A utility class to run tests for your project.
@Deprecated('see [TestRunner]')
class Tests {
  /// Run command-line tests. You can specify the base directory (`test`), and
  /// the file to run (`all.dart`).
   @Deprecated('see [TestRunner]')
  static void runCliTests(
      {String directory: 'test', String testFile: 'all.dart'}) {
    String file = '${directory}/${testFile}';
    log('running tests: ${file}...');
    Dart.run(file);
  }

  /// Run web tests in a browser instance.
  @Deprecated('see [TestRunner]')
  static Future runWebTests({String directory: 'test',
      String htmlFile: 'index.html', dynamic browser}) {
    fail('See the TestRunner class (and the `test` package) in order to run web'
        ' based tests.');
    return new Future.value();
  }
}

/// A wrapper around the `test` package. This class is used to run your unit
/// tests.
class TestRunner {
  final PubApp _test = new PubApp.local('test');

  TestRunner();

  /// Run the tests in the current package. See the
  /// [test package](https://pub.dartlang.org/packages/test).
  ///
  /// [files] - the files or directories to test. This can a path ([String]),
  /// [File], or list of paths or files.
  ///
  /// [name] is substring of the name of the test to run. Regular expression
  /// syntax is supported. [plainName] is a plain-text substring of the name of
  /// the test to run. [platformSelector] is the platform(s) on which to run the
  /// tests. This parameter can be a String or a List.
  /// [Available values](https://github.com/dart-lang/test#platform-selector-syntax)
  /// are `vm` (default), `dartium`, `content-shell`, `chrome`, `phantomjs`,
  /// `firefox`, `safari`. [concurrency] controls the number of concurrent test
  /// suites run (defaults to 4). [pubServe] is the port of a pub serve instance
  /// serving `test/`.
  void test({dynamic files, String name, String plainName,
      dynamic platformSelector, int concurrency, int pubServe,
      RunOptions runOptions}) {
    _test.run(_buildArgs(
        files: files,
        name: name,
        plainName: plainName,
        selector: platformSelector,
        concurrency: concurrency,
        pubServe: pubServe), script: 'test', runOptions: runOptions);
  }

  /// Run the tests in the current package. See the
  /// [test package](https://pub.dartlang.org/packages/test).
  ///
  /// [files] - the files or directories to test. This can a path ([String]),
  /// [File], or list of paths or files.
  ///
  /// [name] is substring of the name of the test to run. Regular expression
  /// syntax is supported. [plainName] is a plain-text substring of the name of
  /// the test to run. [platformSelector] is the platform(s) on which to run the
  /// tests. This parameter can be a String or a List.
  /// [Available values](https://github.com/dart-lang/test#platform-selector-syntax)
  /// are `vm` (default), `dartium`, `content-shell`, `chrome`, `phantomjs`,
  /// `firefox`, `safari`. [concurrency] controls the number of concurrent test
  /// suites run (defaults to 4). [pubServe] is the port of a pub serve instance
  /// serving `test/`.
  Future testAsync({dynamic files, String name, String plainName,
      dynamic platformSelector, int concurrency, int pubServe,
      RunOptions runOptions}) {
    return _test.runAsync(_buildArgs(
        files: files,
        name: name,
        plainName: plainName,
        selector: platformSelector,
        concurrency: concurrency,
        pubServe: pubServe), script: 'test', runOptions: runOptions);
  }

  List<String> _buildArgs({dynamic files, String name, String plainName,
      dynamic selector, int concurrency, int pubServe}) {
    List<String> args = ['--reporter=expanded'];
    if (name != null) args.add('--name=${name}');
    if (plainName != null) args.add('--plain-name=${plainName}');
    if (selector != null) {
      if (selector is List) selector = selector.join('||');
      args.add('--platform=${selector}');
    }
    if (concurrency != null) args.add('--concurrency=${concurrency}');
    if (pubServe != null) args.add('--pub-serve=${pubServe}');
    if (files != null) args.addAll(coerceToPathList(files));
    // TODO: Pass in --color based on a global property: #243.
    return args;
  }
}
