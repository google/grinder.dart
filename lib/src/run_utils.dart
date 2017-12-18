// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.run_utils;

import 'dart:async';
import 'dart:convert';

import 'package:grinder/src/singleton.dart';

import '../grinder.dart';

Stream<String> toLineStream(Stream<List<int>> s, Encoding encoding) =>
    s.transform(encoding.decoder).transform(const LineSplitter());

void logStdout(String line) {
  log(line);
}

void logStderr(String line) {
  log(grinder.ansi.error(line));
}

/// Helper for methods which support the deprecated [workingDirectory] and the
/// new [runOptions] to create a [RunOptions] instance which contains the values
/// of the passed [runOptions] and the passed [workingDirectory].
/// If both [workingDirectory] and [runOptions.workingDirectory] are passed
/// an AssertionError is thrown. Only one of both may be used at one
/// time.
/// This function can probably be removed when the deprecated `workingDirectory`
/// arguments are finally removed.
RunOptions mergeWorkingDirectory(
    String workingDirectory, RunOptions runOptions) {
  if (workingDirectory != null) {
    if (runOptions?.workingDirectory != null) {
      throw new ArgumentError(
          'only one of workingDirectory or runOptions.workingDirectory may be specified');
    }
  }
  return runOptions == null
      ? new RunOptions(workingDirectory: workingDirectory)
      : runOptions.clone(workingDirectory: workingDirectory);
}

/// Helper for methods which support the deprecated [envVar] and the
/// new [runOptions] to create a [RunOptions] instance which contains the values
/// of the passed [runOptions] and the passed [envVar].
/// If both [envVar] and [runOptions.environment] are passed
/// an AssertionError is thrown. Only one of both may be used at one
/// time.
/// This function can probably be removed when the deprecated `envVar`
/// arguments are finally removed.
RunOptions mergeEnvironment(
    Map<String, String> environment, RunOptions runOptions) {
  if (environment != null) {
    assert(runOptions == null ||
        runOptions.environment == null ||
        runOptions.environment.isEmpty);
  }
  return runOptions == null
      ? new RunOptions(environment: environment)
      : runOptions.clone(environment: environment);
}
