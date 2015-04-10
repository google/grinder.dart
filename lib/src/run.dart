// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.run;

import 'dart:async';
import 'dart:io';

import '../grinder.dart';
import 'run_utils.dart';

/// Synchronously run an [executable].
///
/// If [quiet] is false, [log]s the stdout.  The stderr is always logged.
///
/// Returns the stdout.
///
/// All other optional parameters are forwarded to [Process.runSync].
String run(String executable,
    {List<String> arguments : const [],
     bool quiet: false,
     String workingDirectory,
     Map<String, String> environment}) {
  log("${executable} ${arguments.join(' ')}");

  ProcessResult result = Process.runSync(
      executable, arguments, workingDirectory: workingDirectory,
      environment: environment);

  if (!quiet) {
    if (result.stdout != null && result.stdout.isNotEmpty) {
      log(result.stdout.trim());
    }
  }

  if (result.stderr != null && result.stderr.isNotEmpty) {
    log(result.stderr);
  }

  if (result.exitCode != 0) {
    throw new ProcessException._(executable, result.exitCode, result.stdout,
        result.stderr);
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
String runProcess(String executable,
    {List<String> arguments : const [],
     bool quiet: false,
     String workingDirectory,
     Map<String, String> environment}) => run(executable, arguments: arguments,
         quiet: quiet, workingDirectory: workingDirectory,
         environment: environment);

/// Asynchronously run an [executable].
///
/// If [quiet] is false, [log]s the stdout as line breaks are encountered.
/// The stderr is always logged.
///
/// Returns a future for the stdout.
///
/// All other optional parameters are forwarded to [Process.start].
Future<String> runAsync(String executable,
    {List<String> arguments : const [],
     bool quiet: false,
     String workingDirectory}) {

  if (!quiet) log("$executable ${arguments.join(' ')}");

  List<int> stdout = [], stderr = [];

  return Process.start(executable, arguments, workingDirectory: workingDirectory)
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
        throw new ProcessException._(executable, code, stdoutString, SYSTEM_ENCODING.decode(stderr));
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
  {List<String> arguments : const [],
   bool quiet: false,
   String workingDirectory}) => runAsync(executable, arguments: arguments,
       quiet: quiet, workingDirectory: workingDirectory);

/// An exception from a process which exited with a non-zero exit code.
class ProcessException {
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
