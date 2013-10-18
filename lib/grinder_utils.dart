// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/**
 * Commonly used utilities for build scripts, including for tasks like running
 * `pub` commands.
 */
library grinder.utils;

import 'dart:io';

import 'grinder.dart';

/**
 * Utility tasks for executing pub commands.
 */
class PubTools {

  /**
   * Run `pub install` on the current project. If [force] is true, this will
   * execute even if the pubspec.lock file is up-to-date with respect to the
   * pubspec.yaml file.
   */
  void install(GrinderContext context, {bool force: false}) {
    FileSet pubspec = new FileSet.fromFile(new File('pubspec.yaml'));
    FileSet publock = new FileSet.fromFile(new File('pubspec.lock'));

    if (force || !publock.upToDate(pubspec)) {
      runSdkBinary(context, 'pub', arguments: ['install']);
    }
  }

  void update(GrinderContext context, {bool force: false}) {
    FileSet pubspec = new FileSet.fromFile(new File('pubspec.yaml'));
    FileSet publock = new FileSet.fromFile(new File('pubspec.lock'));

    if (force || !publock.upToDate(pubspec)) {
      runSdkBinary(context, 'pub', arguments: ['update']);
    }
  }
}

/**
 * Run the given Dart script in a new process.
 */
void runDartScript(GrinderContext context, String script,
    {List<String> arguments : const [], bool quiet: false, String packageRoot,
    String workingDirectory}) {
  List<String> args = [];

  if (packageRoot != null) {
    args.add('--package-root=${packageRoot}');
  }

  args.add(script);
  args.addAll(arguments);

  runProcess(context, dartVM.path, arguments: args, quiet: quiet,
      workingDirectory: workingDirectory);
}

/**
 * Run the given executable, with optional arguments and working directory.
 */
void runProcess(GrinderContext context, String executable,
    {List<String> arguments : const [],
     bool quiet: false,
     String workingDirectory}) {
  context.log("${executable} ${arguments.join(' ')}");

  ProcessResult result = Process.runSync(
      executable, arguments, workingDirectory: workingDirectory);

  if (!quiet) {
    if (result.stdout != null && !result.stdout.isEmpty) {
      context.log(result.stdout.trim());
    }
  }

  if (result.stderr != null && !result.stderr.isEmpty) {
    context.log(result.stderr);
  }

  if (result.exitCode != 0) {
    throw new GrinderException(
        "${executable} failed with a return code of ${result.exitCode}");
  }
}

/**
 * Run the given Dart SDK binary, with optional arguments and working directory.
 * This should be a script found in `<dart-sdk>/bin`.
 */
void runSdkBinary(GrinderContext context, String script,
    {List<String> arguments : const [], bool quiet: false, String workingDirectory}) {
  File scriptFile = joinFile(sdkDir, ['bin', script]);

  runProcess(context, scriptFile.path, arguments: arguments, quiet: quiet,
             workingDirectory: workingDirectory);
}
