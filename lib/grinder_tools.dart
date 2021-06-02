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

final Directory binDir = Directory('bin');
final Directory buildDir = Directory('build');
final Directory libDir = Directory('lib');
final Directory webDir = Directory('web');

/// Run a dart [script] using [run_lib.run]. Returns the stdout.
///
/// Prefer `Dart.run` instead.
String runDartScript(String script,
    {List<String> arguments = const [],
    bool quiet = false,
    String? packageRoot,
    RunOptions? runOptions,
    String? workingDirectory}) {
  runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
  return Dart.run(script,
      arguments: arguments,
      quiet: quiet,
      packageRoot: packageRoot,
      runOptions: runOptions);
}

/// A default implementation of a `clean` task. This task deletes all generated
/// artifacts in the `build/`.
void defaultClean([GrinderContext? context]) => delete(buildDir);

/// A wrapper around the `test` package. This class is used to run your unit
/// tests.
class TestRunner {
  final PubApp _test = PubApp.local('test');

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
  void test(
      {dynamic files,
      String? name,
      String? plainName,
      dynamic platformSelector,
      int? concurrency,
      int? pubServe,
      RunOptions? runOptions}) {
    _test.run(
        _buildArgs(
            files: files,
            name: name,
            plainName: plainName,
            selector: platformSelector,
            concurrency: concurrency,
            pubServe: pubServe),
        script: 'test',
        runOptions: runOptions);
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
  Future testAsync(
      {dynamic files,
      String? name,
      String? plainName,
      dynamic platformSelector,
      int? concurrency,
      int? pubServe,
      RunOptions? runOptions}) {
    return _test.runAsync(
        _buildArgs(
            files: files,
            name: name,
            plainName: plainName,
            selector: platformSelector,
            concurrency: concurrency,
            pubServe: pubServe),
        script: 'test',
        runOptions: runOptions);
  }

  List<String> _buildArgs(
      {dynamic files,
      String? name,
      String? plainName,
      dynamic selector,
      int? concurrency,
      int? pubServe}) {
    final args = ['--reporter=expanded'];
    if (name != null) args.add('--name=$name');
    if (plainName != null) args.add('--plain-name=$plainName');
    if (selector != null) {
      if (selector is List) selector = selector.join(',');
      args.add('--platform=$selector');
    }
    if (concurrency != null) args.add('--concurrency=$concurrency');
    if (pubServe != null) args.add('--pub-serve=$pubServe');
    if (files != null) args.addAll(coerceToPathList(files));
    // TODO: Pass in --color based on a global property: #243.
    return args;
  }
}

/// A class to drive the Dart Dev Compiler (DDC, from the `dev_compiler` package).
class DevCompiler {
  final PubApp _ddc = PubApp.global('dev_compiler');

  DevCompiler();

  /// Analyze the given file or files with DDC.
  void analyze(dynamic files, {bool htmlReport = false}) {
    _ddc.run(_args(files, htmlReport: htmlReport));
  }

  /// Analyze the given file or files with DDC.
  Future analyzeAsync(dynamic files, {bool htmlReport = false}) {
    return _ddc.runAsync(_args(files, htmlReport: htmlReport));
  }

  /// Compile the given file with DDC and generate the output to [outDir].
  void compile(dynamic files, Directory outDir,
      {bool forceCompile = false, bool htmlReport = false}) {
    _ddc.run(_args(files,
        outDir: outDir, forceCompile: forceCompile, htmlReport: htmlReport));
  }

  /// Compile the given file with DDC and generate the output to [outDir].
  Future compileAsync(dynamic files, Directory outDir,
      {bool forceCompile = false, bool htmlReport = false}) {
    return _ddc.runAsync(_args(files,
        outDir: outDir, forceCompile: forceCompile, htmlReport: htmlReport));
  }

  List<String> _args(dynamic files,
      {Directory? outDir, bool forceCompile = false, bool htmlReport = false}) {
    final args = <String>[];
    if (outDir != null) args.add('-o${outDir.path}');
    if (forceCompile) args.add('--force-compile');
    if (htmlReport) args.add('--html-report');
    args.addAll(coerceToPathList(files));
    return args;
  }
}
