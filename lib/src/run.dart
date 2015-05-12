// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.run;

import 'dart:async';
import 'dart:io';

import '../grinder.dart';
import 'run_utils.dart';
import 'dart:convert';

/// Synchronously run an [executable].
///
/// If [quiet] is false, [log]s the stdout.  The stderr is always logged.
///
/// Returns the stdout.
///
/// All other optional parameters are forwarded to [Process.runSync].
String run(String executable, {List<String> arguments: const [],
    RunOptions runOptions, bool quiet: false}) {
  if (!quiet) log("${executable} ${arguments.join(' ')}");
  if (runOptions == null) {
    runOptions = new RunOptions();
  }

  ProcessResult result = Process.runSync(executable, arguments,
      workingDirectory: runOptions.workingDirectory,
      environment: runOptions.environment,
      includeParentEnvironment: runOptions.includeParentEnvironment,
      runInShell: runOptions.runInShell,
      stdoutEncoding: runOptions.stdoutEncoding,
      stderrEncoding: runOptions.stderrEncoding);

  if (!quiet) {
    if (result.stdout != null && result.stdout.isNotEmpty) {
      log(result.stdout.trim());
    }
  }

  if (result.stderr != null && result.stderr.isNotEmpty) {
    log(result.stderr);
  }

  if (result.exitCode != 0) {
    throw new ProcessException._(
        executable, result.exitCode, result.stdout, result.stderr);
  }

  return result.stdout;
}

/// Synchronously run an [executable].
///
/// If [quiet] is false, [log]s the stdout.  The stderr is always logged.
///
/// Returns the stdout.
///
/// All other optional parameters are forwarded to [Process.runSync].
@Deprecated('Use `run` instead.')
String runProcess(String executable, {List<String> arguments: const [],
        RunOptions runOptions, bool quiet: false}) =>
    run(executable, arguments: arguments, runOptions: runOptions, quiet: quiet);

/// Asynchronously run an [executable].
///
/// If [quiet] is false, [log]s the stdout as line breaks are encountered.
/// The stderr is always logged.
///
/// Returns a future for the stdout.
///
/// All other optional parameters are forwarded to [Process.start].
Future<String> runAsync(String executable, {List<String> arguments: const [],
    RunAsyncOptions runOptions, bool quiet: false}) {
  if (!quiet) log("$executable ${arguments.join(' ')}");
  if (runOptions == null) runOptions = new RunAsyncOptions();
  List<int> stdout = [],
      stderr = [];

  return Process
      .start(executable, arguments,
          workingDirectory: runOptions.workingDirectory,
          environment: runOptions.environment,
          includeParentEnvironment: runOptions.includeParentEnvironment,
          runInShell: runOptions.runInShell,
          mode: runOptions.mode)
      .then((Process process) {

    // Handle stdout.
    var broadcastStdout = process.stdout.asBroadcastStream();
    var stdoutLines = toLineStream(broadcastStdout);
    broadcastStdout.listen((List<int> data) => stdout.addAll(data));
    if (!quiet) {
      stdoutLines.listen(logStdout);
    }

    // Handle stderr.
    var broadcastStderr = process.stderr.asBroadcastStream();
    var stderrLines = toLineStream(broadcastStderr);
    broadcastStderr.listen((List<int> data) => stderr.addAll(data));
    stderrLines.listen(logStderr);

    return process.exitCode.then((int code) {
      var stdoutString = SYSTEM_ENCODING.decode(stdout);

      if (code != 0) {
        throw new ProcessException._(
            executable, code, stdoutString, SYSTEM_ENCODING.decode(stderr));
      }

      return stdoutString;
    });
  });
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
    {List<String> arguments: const [], RunAsyncOptions runOptions,
    bool quiet: false}) => runAsync(executable,
        arguments: arguments, quiet: quiet, runOptions: runOptions);

/// An exception from a process which exited with a non-zero exit code.
class ProcessException implements Exception {
  final String executable;
  final int exitCode;
  final String stdout;
  final String stderr;

  ProcessException._(this.executable, this.exitCode, this.stdout, this.stderr);

  String toString() => """
$executable failed with:
exit code: $exitCode

stdout:

$stdout

stderr:

$stderr""";
}

/// Arguments passed to [Process.run] .
/// See [Process.run] for more details.
class RunOptions {
  String workingDirectory;
  Map<String, String> environment;
  bool includeParentEnvironment;
  bool runInShell;
  Encoding stdoutEncoding;
  Encoding stderrEncoding;

  RunOptions({this.workingDirectory, this.environment,
      this.includeParentEnvironment: true, this.runInShell: false,
      this.stdoutEncoding: SYSTEM_ENCODING,
      this.stderrEncoding: SYSTEM_ENCODING});

  /// Create a clone when it's necessary to modify the passed runOptions to
  /// avoid modifying the argument.
  RunOptions clone() {
    return new RunOptions(
        workingDirectory: workingDirectory,
        environment: environment == null ? null : new Map.from(environment),
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding);
  }
}

/// Arguments passed to [Process.start] .
/// See [Process.start] for more details.
class RunAsyncOptions {
  String workingDirectory;
  Map<String, String> environment;
  bool includeParentEnvironment;
  bool runInShell;
  ProcessStartMode mode;
  RunAsyncOptions({this.workingDirectory, this.environment,
      this.includeParentEnvironment: true, this.runInShell: false,
      this.mode: ProcessStartMode.NORMAL});

  /// Create a clone when it's necessary to modify the passed runOptions to
  /// avoid modifying the argument.
  RunAsyncOptions clone() {
    return new RunAsyncOptions(
        workingDirectory: workingDirectory,
        environment: environment == null ? null : new Map.from(environment),
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        mode: mode);
  }
}
