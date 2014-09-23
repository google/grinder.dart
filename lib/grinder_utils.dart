// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/**
 * Commonly used utilities for build scripts, including for tasks like running
 * `pub` commands.
 */
library grinder.utils;

import 'dart:async';
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

  runProcess(context, 'dart', arguments: args, quiet: quiet,
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
 * Run the given executable, with optional arguments and working directory.
 */
Future runProcessAsync(GrinderContext context, String executable,
    {List<String> arguments : const [],
     bool quiet: false,
     String workingDirectory}) {
  context.log("${executable} ${arguments.join(' ')}");

  return Process.start(executable, arguments, workingDirectory: workingDirectory)
      .then((Process process) {
    // Handle stdout.
    process.stdout.listen((List<int> data) {
      if (!quiet) {
        context.log(new String.fromCharCodes(data).trim());
      }
    });

    // Handle stderr.
    process.stderr.listen((List<int> data) {
      context.log('stderr: ${new String.fromCharCodes(data).trim()}');
    });

    return process.exitCode.then((int code) {
      if (code == 0) {
        return new Future.value();
      } else {
        throw new GrinderException(
            "${executable} failed with a return code of ${code}");
      }
    });
  });
}

/**
 * Utility tasks for executing pub commands.
 */
class Pub {
  /**
   * Run `pub get` on the current project. If [force] is true, this will execute
   * even if the pubspec.lock file is up-to-date with respect to the
   * pubspec.yaml file.
   */
  static void get(GrinderContext context, {bool force: false}) {
    FileSet pubspec = new FileSet.fromFile(new File('pubspec.yaml'));
    FileSet publock = new FileSet.fromFile(new File('pubspec.lock'));

    if (force || !publock.upToDate(pubspec)) {
      _run(context, 'get');
    }
  }

  /**
   * Run `pub get` on the current project. If [force] is true, this will execute
   * even if the pubspec.lock file is up-to-date with respect to the
   * pubspec.yaml file.
   */
  static Future getAsync(GrinderContext context, {bool force: false}) {
    FileSet pubspec = new FileSet.fromFile(new File('pubspec.yaml'));
    FileSet publock = new FileSet.fromFile(new File('pubspec.lock'));

    if (force || !publock.upToDate(pubspec)) {
      return runProcessAsync(context, 'pub', arguments: ['get']);
    } else {
      return new Future.value();
    }
  }

  /**
   * Run `pub upgrade` on the current project.
   */
  static void upgrade(GrinderContext context) => _run(context, 'upgrade');

  /**
   * Run `pub upgrade` on the current project.
   */
  static Future upgradeAsync(GrinderContext context) {
    return runProcessAsync(context, 'pub', arguments: ['upgrade']);
  }

  /**
   * Run `pub build` on the current project.
   *
   * The valid values for [mode] are `release` and `debug`.
   */
  static void build(GrinderContext context,
      {String mode, List<String> directories, String workingDirectory}) {
    List args = ['build'];
    if (mode != null) args.add('--mode=${mode}');
    if (directories != null && directories.isNotEmpty) args.addAll(directories);

    runProcess(context, 'pub', arguments: args,
      workingDirectory: workingDirectory);
  }

  /**
   * Run `pub build` on the current project.
   *
   * The valid values for [mode] are `release` and `debug`.
   */
  static Future buildAsync(GrinderContext context,
      {String mode, List<String> directories, String workingDirectory}) {
    List args = ['build'];
    if (mode != null) args.add('--mode=${mode}');
    if (directories != null && directories.isNotEmpty) args.addAll(directories);

    return runProcessAsync(context, 'pub', arguments: args,
      workingDirectory: workingDirectory);
  }

  static void version(GrinderContext context) => _run(context, '--version');

  static void _run(GrinderContext context, String command) {
    runProcess(context, 'pub', arguments: [command]);
  }
}

/**
 * Utility tasks for invoking dart2js.
 */
class Dart2js {
  /**
   * Invoke a dart2js compile with the given [sourceFile] as input.
   */
  static void compile(GrinderContext context, File sourceFile, {Directory outDir}) {
    // TODO: Check for the out.deps file, use it to know when to compile.
    if (outDir == null) {
      outDir = sourceFile.parent;
    }

    File outFile = joinFile(outDir, ["${fileName(sourceFile)}.js"]);

    runProcess(
        context,
        'dart2js',
        arguments: ['-o${outFile.path}', sourceFile.path]);
  }

  /**
   * Invoke a dart2js compile with the given [sourceFile] as input.
   */
  static Future compileAsync(GrinderContext context, File sourceFile, {Directory outDir}) {
    // TODO: Check for the out.deps file, use it to know when to compile.
    if (outDir == null) {
      outDir = sourceFile.parent;
    }

    File outFile = joinFile(outDir, ["${fileName(sourceFile)}.js"]);

    return runProcessAsync(
        context,
        'dart2js',
        arguments: ['-o${outFile.path}', sourceFile.path]);
  }

  static void version(GrinderContext context) => _run(context, '--version');

  static void _run(GrinderContext context, String command) {
    runProcess(context, 'dart2js', arguments: [command]);
  }
}

/**
 * Utility tasks for invoking the analyzer.
 */
class Analyzer {
  static void analyze(GrinderContext context, File file,
      {Directory packageRoot, bool fatalWarnings: false}) {
    analyzePaths(context, [file.path], packageRoot: packageRoot,
        fatalWarnings: fatalWarnings);
  }

  static void analyzeFiles(GrinderContext context, List<File> files,
      {Directory packageRoot, bool fatalWarnings: false}) {
    analyzePaths(context, files.map((f) => f.path).toList(),
        packageRoot: packageRoot, fatalWarnings: fatalWarnings);
  }

  static void analyzePath(GrinderContext context, String path,
      {Directory packageRoot, bool fatalWarnings: false}) {
    analyzePaths(context, [path], packageRoot: packageRoot,
        fatalWarnings: fatalWarnings);
  }

  static void analyzePaths(GrinderContext context, List<String> paths,
      {Directory packageRoot, bool fatalWarnings: false}) {
    List args = [];
    if (packageRoot != null) args.add('--package-root=${packageRoot.path}');
    if (fatalWarnings) args.add('--fatal-warnings');
    args.addAll(paths);

    runProcess(context, 'dartanalyzer', arguments: args);
  }

  static void version(GrinderContext context) =>
      runProcess(context, 'dartanalyzer', arguments: ['--version']);
}

String _execName(String name) {
  if (Platform.isWindows) {
    return name == 'dart' ? 'dart.exe' : '${name}.bat';
  }

  return name;
}
