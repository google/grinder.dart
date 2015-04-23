// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/// A library to access tools in the Dart SDK.
library grinder.sdk;

import 'dart:async';
import 'dart:io';

import 'package:cli_util/cli_util.dart' as cli_util;
import 'package:which/which.dart';

import 'grinder.dart';
import 'src/run.dart' as run_lib;

bool _sdkOnPath;

/**
 * Return the path to the current Dart SDK. This will return `null` if we are
 * unable to locate the Dart SDK.
 *
 * See also [getSdkDir].
 */
Directory get sdkDir => getSdkDir(grinderArgs());

/**
 * Return the path to the current Dart SDK. This will return `null` if we are
 * unable to locate the Dart SDK.
 *
 * This is an alias for the `cli_util` package's `getSdkDir()` method.
 */
Directory getSdkDir([List<String> cliArgs]) => cli_util.getSdkDir(cliArgs);

File get dartVM => joinFile(sdkDir, ['bin', _sdkBin('dart')]);

/// Utility tasks for for getting information about the Dart VM and for running
/// Dart applications.
class Dart {
  /// Run a dart [script] using [run_lib.run].
  ///
  /// Returns the stdout.
  static String run(String script,
      {List<String> arguments : const [], bool quiet: false,
       String packageRoot, String workingDirectory, int vmNewGenHeapMB,
       int vmOldGenHeapMB}) {
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

    return run_lib.run(_sdkBin('dart'), arguments: args, quiet: quiet,
        workingDirectory: workingDirectory);
  }

  static String version({bool quiet: false}) {
    // TODO: We may want to run `dart --version` in order to know the version
    // of the SDK that grinder has located.
    //run_lib.run(_sdkBin('dart'), arguments: ['--version'], quiet: quiet);
    // The stdout does not have a stable documented format, so use the provided
    // metadata instead.
    return Platform.version.substring(0, Platform.version.indexOf(' '));
  }
}

//class DartSdk {
//  /// Return the path to the current Dart SDK. This will return `null` if we are
//  /// unable to locate the Dart SDK.
//  static Directory get location => sdkDir;
//}

/**
 * Utility tasks for executing pub commands.
 */
class Pub {
  static PubGlobal _global = new PubGlobal._();

  /**
   * Run `pub get` on the current project. If [force] is true, this will execute
   * even if the pubspec.lock file is up-to-date with respect to the
   * pubspec.yaml file.
   */
  static void get({bool force: false, String workingDirectory}) {
    FileSet pubspec = new FileSet.fromFile(new File('pubspec.yaml'));
    FileSet publock = new FileSet.fromFile(new File('pubspec.lock'));

    if (force || !publock.upToDate(pubspec)) {
      _run('get', workingDirectory: workingDirectory);
    }
  }

  /**
   * Run `pub get` on the current project. If [force] is true, this will execute
   * even if the pubspec.lock file is up-to-date with respect to the
   * pubspec.yaml file.
   */
  static Future getAsync({bool force: false, String workingDirectory}) {
    FileSet pubspec = new FileSet.fromFile(new File('pubspec.yaml'));
    FileSet publock = new FileSet.fromFile(new File('pubspec.lock'));

    if (force || !publock.upToDate(pubspec)) {
      return run_lib.runAsync(_sdkBin('pub'), arguments: ['get'],
          workingDirectory: workingDirectory).then((_) => null);
    }

    return new Future.value();
  }

  /**
   * Run `pub upgrade` on the current project.
   */
  static void upgrade({String workingDirectory}) {
    _run('upgrade', workingDirectory: workingDirectory);
  }

  /**
   * Run `pub upgrade` on the current project.
   */
  static Future upgradeAsync({String workingDirectory}) {
    return run_lib.runAsync(_sdkBin('pub'), arguments: ['upgrade'],
        workingDirectory: workingDirectory).then((_) => null);
  }

  /**
   * Run `pub build` on the current project.
   *
   * The valid values for [mode] are `release` and `debug`.
   */
  static void build({
      String mode,
      List<String> directories,
      String workingDirectory,
      String outputDirectory}) {
    List args = ['build'];
    if (mode != null) args.add('--mode=${mode}');
    if (outputDirectory != null) args.add('--output=${outputDirectory}');
    if (directories != null && directories.isNotEmpty) args.addAll(directories);

    run_lib.run(_sdkBin('pub'), arguments: args,
        workingDirectory: workingDirectory);
  }

  /**
   * Run `pub build` on the current project.
   *
   * The valid values for [mode] are `release` and `debug`.
   */
  static Future buildAsync({
      String mode,
      List<String> directories,
      String workingDirectory,
      String outputDirectory}) {
    List args = ['build'];
    if (mode != null) args.add('--mode=${mode}');
    if (outputDirectory != null) args.add('--output=${outputDirectory}');
    if (directories != null && directories.isNotEmpty) args.addAll(directories);

    return run_lib.runAsync(_sdkBin('pub'), arguments: args,
        workingDirectory: workingDirectory).then((_) => null);
  }

  /// Run `pub run` on the given [package] and [script].
  ///
  /// If [script] is null it defaults to the same value as [package].
  static String run(String package,
      {List<String> arguments, String workingDirectory, String script}) {
    var scriptArg = script == null ? package : '$package:$script';
    List args = ['run', scriptArg];
    if (arguments != null) args.addAll(arguments);
    return run_lib.run(_sdkBin('pub'), arguments: args,
        workingDirectory: workingDirectory);
  }

  static String version({bool quiet: false}) => _AppVersion.parse(
      _run('--version', quiet: quiet)).version;

  static PubGlobal get global => _global;

  static String _run(String command, {bool quiet: false, String workingDirectory}) {
    return run_lib.run(_sdkBin('pub'), quiet: quiet, arguments: [command],
        workingDirectory: workingDirectory);
  }
}

/**
 * Utility tasks for invoking dart2js.
 */
class Dart2js {
  /**
   * Invoke a dart2js compile with the given [sourceFile] as input.
   */
  static void compile(File sourceFile,
      {Directory outDir, bool minify: false, bool csp: false}) {
    if (outDir == null) outDir = sourceFile.parent;
    File outFile = joinFile(outDir, ["${fileName(sourceFile)}.js"]);

    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    List args = [];
    if (minify) args.add('--minify');
    if (csp) args.add('--csp');
    args.add('-o${outFile.path}');
    args.add(sourceFile.path);

    run_lib.run(_sdkBin('dart2js'), arguments: args);
  }

  /**
   * Invoke a dart2js compile with the given [sourceFile] as input.
   */
  static Future compileAsync(File sourceFile,
      {Directory outDir, bool minify: false, bool csp: false}) {
    if (outDir == null) outDir = sourceFile.parent;
    File outFile = joinFile(outDir, ["${fileName(sourceFile)}.js"]);

    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    List args = [];
    if (minify) args.add('--minify');
    if (csp) args.add('--csp');
    args.add('-o${outFile.path}');
    args.add(sourceFile.path);

    return run_lib.runAsync(_sdkBin('dart2js'), arguments: args)
        .then((_) => null);
  }

  static String version({bool quiet: false}) =>
      _AppVersion.parse(_run('--version', quiet: quiet)).version;

  static String _run(String command, {bool quiet: false}) =>
      run_lib.run(_sdkBin('dart2js'), quiet: quiet, arguments: [command]);
}

/**
 * Utility tasks for invoking the analyzer.
 */
class Analyzer {
  /// Analyze a single [File] or path ([String]).
  static void analyze(fileOrPath,
      {Directory packageRoot, bool fatalWarnings: false}) {
    analyzeFiles([fileOrPath], packageRoot: packageRoot,
        fatalWarnings: fatalWarnings);
  }

  /// Analyze one or more [File]s or paths ([String]).
  static void analyzeFiles(List files,
      {Directory packageRoot, bool fatalWarnings: false}) {
    List args = [];
    if (packageRoot != null) args.add('--package-root=${packageRoot.path}');
    if (fatalWarnings) args.add('--fatal-warnings');
    args.addAll(files.map((f) => f is File ? f.path : f));

    run_lib.run(_sdkBin('dartanalyzer'), arguments: args);
  }

  static String version({bool quiet: false}) => _AppVersion.parse(run_lib.run(
      _sdkBin('dartanalyzer'), quiet: quiet, arguments: ['--version'])).version;
}

/// Utility class for invoking `dartfmt` from the SDK.
class DartFmt {
  /// Run the `dartfmt` command with the `--overwrite` option. Format any files
  /// in place.
  static void format(fileOrPath) {
    if (fileOrPath is File) fileOrPath = fileOrPath.path;
    _run('--overwrite', fileOrPath);
  }

  /// Run the `dartfmt` command with the `--dry-run` option. Return `true` if
  /// any files would be changed by running the formatter.
  static bool dryRun(fileOrPath) {
    if (fileOrPath is File) fileOrPath = fileOrPath.path;
    String results = _run('--dry-run', fileOrPath);
    return results.trim().isNotEmpty;
  }

  static String _run(String option, String target, {bool quiet: false}) =>
      run_lib.run(_sdkBin('dartfmt'), quiet: quiet, arguments: [option, target]);
}

/// Access the `pub global` commands.
class PubGlobal {
  Set<String> _activatedPackages;

  PubGlobal._();

  /// Install a new Dart application.
  void activate(String packageName, {bool force: false}) {
    if (force || !isActivated(packageName)) {
      run_lib.run(_sdkBin('pub'), arguments: ['global', 'activate', packageName]);
      _activatedPackages.add(packageName);
    }
  }

  /// Run the given installed Dart application.
  String run(String package,
      {List<String> arguments, String workingDirectory, String script}) {
    var scriptArg = script == null ? package : '$package:$script';
    List args = ['global', 'run', scriptArg];
    if (arguments != null) args.addAll(arguments);
    return run_lib.run(_sdkBin('pub'), arguments: args,
        workingDirectory: workingDirectory);
  }

  /// Return the list of installed applications.
  List<_AppVersion> _list() {
    //dart_coveralls 0.1.8
    //den 0.1.3
    //discoveryapis_generator 0.6.1
    //...

    var stdout = run_lib.run(
        _sdkBin('pub'), arguments: ['global', 'list'], quiet: true);

    var lines = stdout.trim().split('\n');
    return lines.map((line) {
      line = line.trim();
      if (!line.contains(' ')) return new _AppVersion(line);
      var parts = line.split(' ');
      return new _AppVersion(parts.first, parts[1]);
    }).toList();
  }

  /// Returns whether the given Dart application is installed.
  bool isActivated(String packageName) {
    if (_activatedPackages == null) _initActivated();
    return _activatedPackages.contains(packageName);
  }

  void _initActivated() {
    if (_activatedPackages == null) {
      _activatedPackages = new Set();
      _activatedPackages.addAll(_list().map((appVer) => appVer.name));
    }
  }
}

/// A Dart command-line application, installed via `pub global activate`.
abstract class PubApp {
  final String packageName;

  PubApp._(this.packageName);

  /// Create a new reference to a pub application; [packageName] is the same as the
  /// package name.
  factory PubApp.global(String packageName) => new _PubGlobalApp(packageName);

  /// Create a new reference to a pub application; [packageName] is the same as the
  /// package name.
  factory PubApp.local(String packageName) => new _PubLocalApp(packageName);

  bool get isGlobal;

  bool get isActivated;

  /// Install the application (run `pub global activate`). Setting [force] to
  /// try will force the activation of the package even if it is already
  /// installed.
  void activate({bool force: false});

  /// Run the application. If the application is not installed this command will
  /// first activate it.
  ///
  /// If [script] is provided, the sub-script will be run. So
  /// `new PubApp.global('grinder').run(script: 'init');` will run
  /// `grinder:init`.
  String run(List<String> arguments, {String script, String workingDirectory});

  String toString() => packageName;
}

String _sdkBin(String name) {
  if (Platform.isWindows) {
    return name == 'dart' ? 'dart.exe' : '${name}.bat';
  } else if (Platform.isMacOS) {
    // If `dart` is not visible, we should join the sdk path and `bin/$name`.
    // This is only necessary in unusual circumstances, like when the script is
    // run from the Editor on macos.
    if (_sdkOnPath == null) {
      _sdkOnPath = whichSync('dart', orElse: () => null) != null;
    }

    return _sdkOnPath ? name : '${sdkDir.path}/bin/${name}';
  } else {
    return name;
  }
}

/// A version/app name pair.
class _AppVersion {
  final String name;
  final String version;

  _AppVersion(this.name, [this.version]);

  static _AppVersion parse(String output) {
    var lastSpace = output.lastIndexOf(' ');
    if (lastSpace == -1) return new _AppVersion(output);
    return new _AppVersion(output.substring(0, lastSpace),
        output.substring(lastSpace + 1));
  }

  String toString() => '$name $version';
}

class _PubGlobalApp extends PubApp {
  _PubGlobalApp(String packageName) : super._(packageName);

  bool get isGlobal => true;

  bool get isActivated => Pub.global.isActivated(packageName);

  void activate({bool force: false}) =>
      Pub.global.activate(packageName, force: force);

  String run(List<String> arguments, {String script, String workingDirectory}) {
    activate();

    return Pub.global.run(packageName,
        script: script,
        arguments: arguments,
        workingDirectory: workingDirectory);
  }
}

class _PubLocalApp extends PubApp {
  _PubLocalApp(String packageName) : super._(packageName);

  bool get isGlobal => false;

  // TODO: Implement: call a `Pub.isActivated/Pub.isInstalled`.
  bool get isActivated => throw new UnsupportedError('unimplemented');

  void activate({bool force: false}) { }

  String run(List<String> arguments, {String script, String workingDirectory}) {
    return Pub.run(packageName,
        script: script,
        arguments: arguments,
        workingDirectory: workingDirectory);
  }
}
