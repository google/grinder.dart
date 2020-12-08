// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.run;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../grinder.dart';
import 'run_utils.dart';

/// Synchronously run an [executable].
///
/// If [quiet] is false, [log]s the stdout. The stderr is always logged.
///
/// Returns the stdout.
///
/// All other optional parameters are forwarded to [Process.runSync].
String run(String executable,
    {List<String> arguments = const [],
    RunOptions? runOptions,
    bool quiet = false,
    String? workingDirectory}) {
  runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
  if (!quiet) log("${executable} ${arguments.join(' ')}");

  final result = Process.runSync(executable, arguments,
      workingDirectory: runOptions.workingDirectory,
      environment: runOptions.environment,
      includeParentEnvironment: runOptions.includeParentEnvironment,
      runInShell: runOptions.runInShell,
      stdoutEncoding: runOptions.stdoutEncoding,
      stderrEncoding: runOptions.stderrEncoding);

  var stdout = result.stdout as String;
  var stderr = result.stderr as String;

  if (!quiet && stdout.isNotEmpty) log(stdout.trim());
  if (stderr.isNotEmpty) log(result.stderr);

  if (result.exitCode != 0) {
    throw ProcessException._(executable, result.exitCode, stdout, stderr);
  }

  return stdout;
}

/// Synchronously run an [executable].
///
/// If [quiet] is false, [log]s the stdout. The stderr is always logged.
///
/// Returns the stdout.
///
/// All other optional parameters are forwarded to [Process.runSync].
@Deprecated('Use `run` instead.')
String runProcess(String executable,
    {List<String> arguments = const [],
    RunOptions? runOptions,
    bool quiet = false,
    String? workingDirectory}) {
  runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
  return run(executable,
      arguments: arguments, runOptions: runOptions, quiet: quiet);
}

/// Asynchronously run an [executable].
///
/// If [quiet] is false, [log]s the stdout as line breaks are encountered.
/// The stderr is always logged.
///
/// Returns a future for the stdout.
///
/// All other optional parameters are forwarded to [Process.start].
Future<String> runAsync(String executable,
    {List<String> arguments = const [],
    RunOptions? runOptions,
    bool quiet = false,
    String? workingDirectory}) async {
  runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
  if (!quiet) log("$executable ${arguments.join(' ')}");
  final stdout = <int>[], stderr = <int>[];

  var process = await Process.start(executable, arguments,
          workingDirectory: runOptions.workingDirectory,
          environment: runOptions.environment,
          includeParentEnvironment: runOptions.includeParentEnvironment,
          runInShell: runOptions.runInShell);
    // Handle stdout.
    var broadcastStdout = process.stdout.asBroadcastStream();
    var stdoutLines = toLineStream(broadcastStdout, runOptions.stdoutEncoding);
    broadcastStdout.listen((List<int> data) => stdout.addAll(data));
    if (!quiet) {
      stdoutLines.listen(logStdout);
    }

    // Handle stderr.
    var broadcastStderr = process.stderr.asBroadcastStream();
    var stderrLines = toLineStream(broadcastStderr, runOptions.stderrEncoding);
    broadcastStderr.listen((List<int> data) => stderr.addAll(data));
    stderrLines.listen(logStderr);

    var encoding = runOptions.stdoutEncoding;
  var code = await process.exitCode;
      var stdoutString = encoding.decode(stdout);

      if (code != 0) {
        throw ProcessException._(
            executable, code, stdoutString, encoding.decode(stderr));
      }

      return stdoutString;
}

/// Asynchronously run an [executable].
///
/// If [quiet] is false, [log]s the stdout as line breaks are encountered.
/// The stderr is always logged.
///
/// Returns a future for the stdout.
///
/// All other optional parameters are forwarded to [Process.start].
@Deprecated('Use `runAsync` instead.')
Future<String> runProcessAsync(String executable,
    {List<String> arguments = const [],
    RunOptions? runOptions,
    String? workingDirectory,
    bool quiet = false}) {
  runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
  return runAsync(executable,
      arguments: arguments, quiet: quiet, runOptions: runOptions);
}

/// An exception from a process which exited with a non-zero exit code.
class ProcessException implements Exception {
  final String executable;
  final int exitCode;
  final String stdout;
  final String stderr;

  ProcessException._(this.executable, this.exitCode, this.stdout, this.stderr);

  @override
  String toString() => 'failed with exit code ${exitCode}';
}

/// Arguments passed to [Process.run] or [Process.start].
/// See [Process.run] for more details.
class RunOptions {
  final String? workingDirectory;
  final Map<String, String> environment;
  final bool includeParentEnvironment;
  final bool runInShell;
  final Encoding stdoutEncoding;
  final Encoding stderrEncoding;

  RunOptions(
      {this.workingDirectory,
      Map<String, String>? environment,
      this.includeParentEnvironment = true,
      this.runInShell = false,
      this.stdoutEncoding = systemEncoding,
      this.stderrEncoding = systemEncoding})
      : environment = environment ?? {};

  /// Create a clone with updated values in one step.
  /// For omitted parameters values of the original instance are copied.
  RunOptions clone(
      {String? workingDirectory,
      Map<String, String>? environment,
      bool? includeParentEnvironment,
      bool? runInShell,
      Encoding? stdoutEncoding,
      Encoding? stderrEncoding}) {
    return RunOptions(
        workingDirectory: workingDirectory ?? this.workingDirectory,
        environment: environment != null
            ? Map.from(environment)
            : Map.from(this.environment),
        includeParentEnvironment:
            includeParentEnvironment ?? this.includeParentEnvironment,
        runInShell: runInShell ?? this.runInShell,
        stdoutEncoding: stdoutEncoding ?? this.stdoutEncoding,
        stderrEncoding: stderrEncoding ?? this.stderrEncoding);
  }
}
