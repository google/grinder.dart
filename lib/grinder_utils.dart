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
 * Return the path to the current Dart SDK.
 */
Directory get sdkDir {
  // look for --dart-sdk on the command line
  List<String> args = new Options().arguments;
  // TODO:
  if (args.contains('--dart-sdk')) {
    return new Directory(args[args.indexOf('dart-sdk') + 1]);
  }

  // look in env['DART_SDK']
  if (Platform.environment['DART_SDK'] != null) {
    return new Directory(Platform.environment['DART_SDK']);
  }

  // look relative to the dart executable
  // TODO: file a bug re: the path to the executable and the cwd
  return new File(Platform.executable).parent.parent;
}

File get dartVM => joinFile(sdkDir, ['bin', _execName('dart')]);

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

  runSdkBinary(context, 'dart', arguments: args, quiet: quiet,
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
  File scriptFile = joinFile(sdkDir, ['bin', _execName(script)]);

  runProcess(context, scriptFile.path, arguments: arguments, quiet: quiet,
             workingDirectory: workingDirectory);
}

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
 * Utility tasks for executing pub commands.
 */
class Dart2jsTools {

  /**
   * Run `pub install` on the current project. If [force] is true, this will
   * execute even if the pubspec.lock file is up-to-date with respect to the
   * pubspec.yaml file.
   */
  void compile(GrinderContext context, File sourceFile, {Directory outDir}) {
//    // TODO: check for the out.deps file, us it to know when to compile
//    FileSet pubspec = new FileSet.fromFile(new File('pubspec.yaml'));
//    FileSet publock = new FileSet.fromFile(new File('pubspec.lock'));

    if (outDir == null) {
      outDir = sourceFile.directory;
    }

    File outFile = joinFile(outDir, ["${fileName(sourceFile)}.js"]);

    runSdkBinary(context, 'dart2js',
        arguments: ['-o${outFile.path}', sourceFile.path]);
  }
}

String _execName(String name) => Platform.isWindows ? "${name}.exe" : name;
