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
 * Return the path to the current Dart SDK. This will return `null` if we are
 * unable to locate the Dart SDK.
 */
Directory get sdkDir {
  // Look for --dart-sdk on the command line.
  List<String> args = grinderArgs();
  if (args != null && args.contains('--dart-sdk')) {
    return new Directory(args[args.indexOf('dart-sdk') + 1]);
  }

  // Look in env['DART_SDK']
  if (Platform.environment['DART_SDK'] != null) {
    return new Directory(Platform.environment['DART_SDK']);
  }

  // Look relative to the dart executable.
  // TODO: File a bug re: the path to the executable and the cwd.
  Directory maybeSdkDirectory = new File(Platform.executable).parent.parent;
  return joinFile(maybeSdkDirectory, ['version']).existsSync() ?
      maybeSdkDirectory : null;
}

File get dartVM => joinFile(sdkDir, ['bin', _execName('dart')]);

/**
 * Run the given Dart script in a new process.
 */
void runDartScript(GrinderContext context, String script,
    {List<String> arguments : const [], bool quiet: false, String packageRoot,
    String workingDirectory, int vmNewGenHeapMB, int vmOldGenHeapMB}) {
  List<String> args = [];

  if (packageRoot != null) {
    args.add('--package-root=${packageRoot}');
  }

  if (vmNewGenHeapMB != null) {
    args.add('--new_gen_heap_size=${vmNewGenHeapMB}');
  }

  if (vmOldGenHeapMB != null) {
    args.add('--old_gen_heap_size=${vmOldGenHeapMB}');
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
    {List<String> arguments : const [],
     bool quiet: false,
     String workingDirectory}) {
  File scriptFile = joinFile(sdkDir, ['bin', _execName(script)]);

  runProcess(context, scriptFile.path, arguments: arguments, quiet: quiet,
             workingDirectory: workingDirectory);
}

/**
 * Utility tasks for executing pub commands.
 */
class PubTools {
  /**
   * Run `pub get` on the current project. If [force] is true, this will execute
   * even if the pubspec.lock file is up-to-date with respect to the
   * pubspec.yaml file.
   */
  void get(GrinderContext context, {bool force: false}) {
    FileSet pubspec = new FileSet.fromFile(new File('pubspec.yaml'));
    FileSet publock = new FileSet.fromFile(new File('pubspec.lock'));

    if (force || !publock.upToDate(pubspec)) {
      runSdkBinary(context, 'pub', arguments: ['get']);
    }
  }

  /**
   * Run `pub upgrade` on the current project.
   */
  void upgrade(GrinderContext context) {
    runSdkBinary(context, 'pub', arguments: ['upgrade']);
  }

  /**
   * Run `pub build` on the current project.
   *
   * The valid values for [mode] are `release` and `debug`.
   */
  void build(GrinderContext context, {String mode}) {
    List args = ['build'];
    if (mode != null) {
      args.add('--mode=${mode}');
    }
    runSdkBinary(context, 'pub', arguments: args);
  }
}

/**
 * Utility tasks for invoking dart2js.
 */
class Dart2jsTools {
  /**
   * Invoke a dart2js compile with the given [sourceFile] as input.
   */
  void compile(GrinderContext context, File sourceFile, {Directory outDir}) {
    // TODO: check for the out.deps file, use it to know when to compile
    if (outDir == null) {
      outDir = sourceFile.parent;
    }

    File outFile = joinFile(outDir, ["${fileName(sourceFile)}.js"]);

    runSdkBinary(
        context,
        'dart2js',
        arguments: ['-o${outFile.path}', sourceFile.path]);
  }
}

String _execName(String name) {
  if (Platform.isWindows) {
    return name == 'dart' ? 'dart.exe' : '${name}.bat';
  }

  return name;
}
