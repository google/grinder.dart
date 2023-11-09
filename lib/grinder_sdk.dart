// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/// A library to access tools in the Dart SDK.
library grinder.sdk;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'grinder.dart';
import 'src/run.dart' as runlib;
import 'src/run_utils.dart';
import 'src/utils.dart';

/// A set of common top-level directories according to the Pub package layout
/// convention which usually contain Dart source code.
final Set<Directory> sourceDirs = [
  'bin',
  'example',
  'lib',
  'test',
  'tool',
  'web'
].map((path) => Directory(path)).toSet();

/// The subset of directories in [sourceDirs] which actually exist in the
/// current working directory.
Set<Directory> get existingSourceDirs => Directory.current
    .listSync()
    .whereType<Directory>()
    .map((d) => Directory(path.relative(d.path)))
    .where((d) => sourceDirs.any((sd) => sd.path == d.path))
    .toSet();

/// The path to the current Dart SDK.
final Directory sdkDir =
    Directory(path.dirname(path.dirname(Platform.resolvedExecutable)));

/// This is deprecated.
///
/// Use [sdkDir] instead.
@Deprecated('Use sdkDir to get the current SDK directory instead.')
Directory getSdkDir([List<String>? cliArgs]) => sdkDir;

final File dartVM = File(Platform.resolvedExecutable);

/// Return the path to a binary in the SDK's `bin/` directory. This will handle
/// appending `.bat` or `.exe` on Windows. This is useful for finding the path
/// to SDK utilities like `dartdoc`, `dart2js`, ...
String sdkBin(String name) {
  if (!Platform.isWindows) return path.join(sdkDir.path, 'bin', name);
  if (name == 'dart') return Platform.resolvedExecutable;
  return path.join(sdkDir.path, 'bin', '$name.bat');
}

/// Utility tasks for for getting information about the Dart VM and for running
/// Dart applications.
///
/// The custom named parameters (e.g. vmNewGenHeapMB) will override
/// args set in `vmArgs`.
class Dart {
  /// Run a dart [script] using [runlib.run]. Returns the stdout.
  static String run(
    String script, {
    List<String> arguments = const [],
    bool quiet = false,
    String? packageRoot,
    RunOptions? runOptions,
    String? workingDirectory,
    List<String> vmArgs = const [],
  }) {
    runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
    final args = _buildArgs(script, arguments, packageRoot, vmArgs);

    return runlib.run(dartVM.path,
        arguments: args, quiet: quiet, runOptions: runOptions);
  }

  static Future<String> runAsync(
    String script, {
    List<String> arguments = const [],
    bool quiet = false,
    String? packageRoot,
    RunOptions? runOptions,
    List<String> vmArgs = const [],
  }) {
    final args = _buildArgs(script, arguments, packageRoot, vmArgs);

    return runlib.runAsync(dartVM.path,
        arguments: args, quiet: quiet, runOptions: runOptions);
  }

  static String version({@Deprecated('No longer used.') bool quiet = false}) {
    return Platform.version.substring(0, Platform.version.indexOf(' '));
  }

  static List<String> _buildArgs(String script, List<String> arguments,
      String? packageRoot, List<String> vmArgs) {
    final args = List.of(vmArgs);

    if (packageRoot != null) {
      args.add('--package-root=$packageRoot');
    }

    return args
      ..add(script)
      ..addAll(arguments);
  }
}

/// Utility tasks for executing pub commands.
class Pub {
  static final PubGlobal _global = PubGlobal._();

  /// Run `pub get` on the current project. If [force] is true, this will execute
  /// even if the pubspec.lock file is up-to-date with respect to the
  /// pubspec.yaml file.
  static void get(
      {bool force = false, RunOptions? runOptions, String? workingDirectory}) {
    runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
    final prefix = runOptions.workingDirectory == null
        ? ''
        : '${runOptions.workingDirectory}/';
    final pubspec = FileSet.fromFile(getFile('${prefix}pubspec.yaml'));
    final publock = FileSet.fromFile(getFile('${prefix}pubspec.lock'));

    if (force || !publock.upToDate(pubspec)) {
      _run('get', runOptions: runOptions);
    }
  }

  /// Run `pub get` on the current project. If [force] is true, this will execute
  /// even if the pubspec.lock file is up-to-date with respect to the
  /// pubspec.yaml file.
  static Future getAsync(
      {bool force = false, RunOptions? runOptions, String? workingDirectory}) {
    runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
    final prefix = runOptions.workingDirectory == null
        ? ''
        : '${runOptions.workingDirectory}/';
    final pubspec = FileSet.fromFile(getFile('${prefix}pubspec.yaml'));
    final publock = FileSet.fromFile(getFile('${prefix}pubspec.lock'));

    if (force || !publock.upToDate(pubspec)) {
      return runlib
          .runAsync(sdkBin('dart'),
              arguments: ['pub', 'get'], runOptions: runOptions)
          .then((_) => null);
    }

    return Future.value();
  }

  /// Run `pub upgrade` on the current project.
  static void upgrade({RunOptions? runOptions, String? workingDirectory}) {
    runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
    _run('upgrade', runOptions: runOptions);
  }

  /// Run `pub upgrade` on the current project.
  static Future upgradeAsync(
      {RunOptions? runOptions, String? workingDirectory}) {
    runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
    return runlib
        .runAsync(sdkBin('dart'),
            arguments: ['pub', 'upgrade'], runOptions: runOptions)
        .then((_) => null);
  }

  /// Run `pub downgrade` on the current project.
  static void downgrade({RunOptions? runOptions, String? workingDirectory}) {
    runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
    _run('downgrade', runOptions: runOptions);
  }

  /// Run `pub downgrade` on the current project.
  static Future downgradeAsync(
      {RunOptions? runOptions, String? workingDirectory}) {
    runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
    return runlib
        .runAsync(sdkBin('dart'),
            arguments: ['pub', 'downgrade'], runOptions: runOptions)
        .then((_) => null);
  }

  /// Run `pub build` on the current project.
  ///
  /// The valid values for [mode] are `release` and `debug`.
  static void build({
    String? mode,
    List<String>? directories,
    RunOptions? runOptions,
    String? outputDirectory,
    String? workingDirectory,
  }) {
    runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
    final args = ['pub', 'build'];
    if (mode != null) args.add('--mode=$mode');
    if (outputDirectory != null) args.add('--output=$outputDirectory');
    if (directories != null && directories.isNotEmpty) args.addAll(directories);

    runlib.run(sdkBin('dart'), arguments: args, runOptions: runOptions);
  }

  /// Run `pub build` on the current project.
  ///
  /// The valid values for [mode] are `release` and `debug`.
  static Future buildAsync(
      {String? mode,
      List<String>? directories,
      RunOptions? runOptions,
      String? outputDirectory,
      String? workingDirectory}) {
    runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
    final args = ['pub', 'build'];
    if (mode != null) args.add('--mode=$mode');
    if (outputDirectory != null) args.add('--output=$outputDirectory');
    if (directories != null && directories.isNotEmpty) args.addAll(directories);

    return runlib
        .runAsync(sdkBin('dart'), arguments: args, runOptions: runOptions)
        .then((_) => null);
  }

  /// Run `pub run` on the given [package] and [script].
  ///
  /// If [script] is null it defaults to the same value as [package].
  static String run(String package,
      {List<String>? arguments,
      RunOptions? runOptions,
      String? script,
      String? workingDirectory}) {
    runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
    var scriptArg = script == null ? package : '$package:$script';
    final args = ['pub', 'run', scriptArg];
    if (arguments != null) args.addAll(arguments);
    return runlib.run(sdkBin('dart'), arguments: args, runOptions: runOptions);
  }

  /// Run `pub run` on the given [package] and [script].
  ///
  /// If [script] is null it defaults to the same value as [package].
  static Future<String> runAsync(String package,
      {List<String>? arguments, RunOptions? runOptions, String? script}) {
    var scriptArg = script == null ? package : '$package:$script';
    final args = ['pub', 'run', scriptArg];
    if (arguments != null) args.addAll(arguments);
    return runlib.runAsync(sdkBin('dart'),
        arguments: args, runOptions: runOptions);
  }

  static PubGlobal get global => _global;

  static String _run(String command,
      {bool quiet = false, RunOptions? runOptions}) {
    return runlib.run(sdkBin('dart'),
        quiet: quiet, arguments: ['pub', command], runOptions: runOptions);
  }
}

/// Utility tasks for invoking dart2js.
class Dart2js {
  static List<String> _buildArgs(
          {required bool minify,
          required bool csp,
          required bool enableExperimentalMirrors,
          String? categories,
          required List<String> extraArgs,
          required File outFile,
          required File sourceFile}) =>
      [
        'compile',
        'js',
        if (minify) '--minify',
        if (csp) '--csp',
        if (enableExperimentalMirrors) '--enable-experimental-mirrors',
        if (categories != null) '--categories=$categories',
        ...extraArgs,
        '-o${outFile.path}',
        sourceFile.path
      ];

  /// Invoke a dart2js compile with the given [sourceFile] as input.
  static void compile(File sourceFile,
      {Directory? outDir,
      File? outFile,
      bool minify = false,
      bool csp = false,
      bool enableExperimentalMirrors = false,
      String? categories,
      List<String> extraArgs = const []}) {
    if (outFile == null) {
      outDir ??= sourceFile.parent;
      outFile = joinFile(outDir, ['${fileName(sourceFile)}.js']);
    } else {
      outDir = outFile.parent;
    }

    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    runlib.run(sdkBin('dart'),
        arguments: _buildArgs(
            minify: minify,
            csp: csp,
            enableExperimentalMirrors: enableExperimentalMirrors,
            categories: categories,
            extraArgs: extraArgs,
            outFile: outFile,
            sourceFile: sourceFile));
  }

  /// Invoke a dart2js compile with the given [sourceFile] as input.
  static Future compileAsync(File sourceFile,
      {Directory? outDir,
      File? outFile,
      bool minify = false,
      bool csp = false,
      bool enableExperimentalMirrors = false,
      String? categories,
      List<String> extraArgs = const []}) {
    if (outFile == null) {
      outDir ??= sourceFile.parent;
      outFile = joinFile(outDir, ['${fileName(sourceFile)}.js']);
    } else {
      outDir = outFile.parent;
    }

    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    return runlib
        .runAsync(sdkBin('dart'),
            arguments: _buildArgs(
                minify: minify,
                csp: csp,
                enableExperimentalMirrors: enableExperimentalMirrors,
                categories: categories,
                extraArgs: extraArgs,
                outFile: outFile,
                sourceFile: sourceFile))
        .then((_) => null);
  }

  static String? version({bool quiet = false}) =>
      _parseVersion(_run('--version', quiet: quiet));

  static String _run(String command, {bool quiet = false}) => runlib
      .run(sdkBin('dart'), quiet: quiet, arguments: ['compile', 'js', command]);
}

/// Utility class for invoking dartdoc.
class DartDoc {
  static void doc() {
    runlib.run(sdkBin('dart'), arguments: ['doc']);
  }

  static Future docAsync() =>
      runlib.runAsync(sdkBin('dart'), arguments: ['doc']);
}

/// Utility tasks for invoking the analyzer.
class Analyzer {
  /// Analyze a [File], a path ([String]), or a list of files or paths.
  static void analyze(fileOrPaths,
      {Directory? packageRoot, bool fatalWarnings = false}) {
    runlib.run(sdkBin('dart'), arguments: [
      'analyze',
      if (packageRoot != null) '--package-root=${packageRoot.path}',
      if (fatalWarnings) '--fatal-warnings',
      fileOrPaths
    ]);
  }

  /// Analyze one or more [File]s or paths ([String]).
  @Deprecated('see `analyze`, which now takes a list as an argument')
  static void analyzeFiles(List files,
      {Directory? packageRoot, bool fatalWarnings = false}) {
    runlib.run(sdkBin('dart'), arguments: [
      'analyze',
      if (packageRoot != null) '--package-root=${packageRoot.path}',
      if (fatalWarnings) '--fatal-warnings',
      ...coerceToPathList(files)
    ]);
  }

  static String? version({bool quiet = false}) => _parseVersion(runlib
      .run(sdkBin('dart'), quiet: quiet, arguments: ['analyze', '--version']));
}

/// Utility class for invoking `dartfmt` from the SDK. This wrapper requires
/// the `dartfmt` from SDK 1.9 and greater.
class DartFmt {
  /// Run the `dartfmt` command with the `--overwrite` option. Format a file, a
  /// directory or a list of files or directories in place.
  static void format(fileOrPath, {int? lineLength}) {
    _run(const [], coerceToPathList(fileOrPath), lineLength: lineLength);
  }

  /// Run the `dartfmt` command with the `--dry-run` option. Return `true` if
  /// any files would be changed by running the formatter.
  static bool dryRun(fileOrPath, {int? lineLength}) {
    try {
      _run(
        ['--output=none', '--set-exit-if-changed'],
        coerceToPathList(fileOrPath),
        lineLength: lineLength,
      );
      return false;
    } on ProcessException catch (e) {
      if (e.exitCode == 1) {
        return true;
      }
      rethrow;
    }
  }

  static String _run(
    List<String> options,
    List<String> targets, {
    bool quiet = false,
    int? lineLength,
  }) {
    final args = <String>['format', ...options];
    if (lineLength != null) {
      args.add('--line-length=$lineLength');
    }
    args.addAll(targets);
    return runlib.run(sdkBin('dart'), quiet: quiet, arguments: args);
  }
}

/// Access the `pub global` commands.
class PubGlobal {
  late final Set<String> _activatedPackages =
      list().map((app) => app.packageName).toSet();

  PubGlobal._();

  /// Install a new Dart application.
  void activate(String packageName, {bool force = false}) {
    if (force || !isActivated(packageName)) {
      runlib.run(sdkBin('dart'),
          arguments: ['pub', 'global', 'activate', packageName]);
      _activatedPackages.add(packageName);
    }
  }

  /// Run the given installed Dart application.
  String run(String package,
      {List<String>? arguments,
      RunOptions? runOptions,
      String? script,
      String? workingDirectory}) {
    runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
    var scriptArg = script == null ? package : '$package:$script';
    final args = ['pub', 'global', 'run', scriptArg];
    if (arguments != null) args.addAll(arguments);
    return runlib.run(sdkBin('dart'), arguments: args, runOptions: runOptions);
  }

  /// Run the given installed Dart application.
  Future<String> runAsync(String package,
      {List<String>? arguments, RunOptions? runOptions, String? script}) {
    var scriptArg = script == null ? package : '$package:$script';
    final args = ['pub', 'global', 'run', scriptArg];
    if (arguments != null) args.addAll(arguments);
    return runlib.runAsync(sdkBin('dart'),
        arguments: args, runOptions: runOptions);
  }

  /// Return the list of installed applications.
  List<PubApp> list() {
    //dart_coveralls 0.1.8
    //den 0.1.3
    //discoveryapis_generator 0.6.1
    //...

    var stdout = runlib.run(sdkBin('dart'),
        arguments: ['pub', 'global', 'list'], quiet: true);

    var lines = stdout.trim().split('\n');
    return lines.map((line) {
      line = line.trim();
      if (!line.contains(' ')) return PubApp.global(line);
      return PubApp.global(line.split(' ').first);
    }).toList();
  }

  /// Returns whether the given Dart application is installed.
  bool isActivated(String packageName) =>
      _activatedPackages.contains(packageName);
}

/// A Dart command-line application, installed via `pub global activate`.
abstract class PubApp {
  final String packageName;

  PubApp._(this.packageName);

  /// Create a new reference to a pub application; [packageName] is the same as the
  /// package name.
  factory PubApp.global(String packageName) => _PubGlobalApp(packageName);

  /// Create a new reference to a pub application; [packageName] is the same as the
  /// package name.
  factory PubApp.local(String packageName) => _PubLocalApp(packageName);

  bool get isGlobal;

  bool get isActivated;

  /// Install the application (run `pub global activate`). Setting [force] to
  /// try will force the activation of the package even if it is already
  /// installed.
  void activate({bool force = false});

  /// Run the application. If the application is not installed this command will
  /// first activate it.
  ///
  /// If [script] is provided, the sub-script will be run. So
  /// `new PubApp.global('grinder').run(script: 'init');` will run
  /// `grinder:init`.
  String run(List<String> arguments,
      {String? script, RunOptions? runOptions, String? workingDirectory});

  /// Run the application. If the application is not installed this command will
  /// first activate it.
  ///
  /// If [script] is provided, the sub-script will be run. So
  /// `new PubApp.global('grinder').runAsync(script: 'init');` will run
  /// `grinder:init`.
  Future<String> runAsync(List<String> arguments,
      {String? script, RunOptions? runOptions});

  @override
  String toString() => packageName;
}

/// Parse the version out of strings like:
///
///     dart_coveralls 0.1.11
///     pub_cache 0.0.1 at path "/Users/foobar/projects/pub_cache"
String? _parseVersion(String output) {
  final tokens = output.split(' ');
  return tokens.length < 2 ? null : tokens[1];
}

class _PubGlobalApp extends PubApp {
  _PubGlobalApp(super.packageName) : super._();

  @override
  bool get isGlobal => true;

  @override
  bool get isActivated => Pub.global.isActivated(packageName);

  @override
  void activate({bool force = false}) =>
      Pub.global.activate(packageName, force: force);

  @override
  String run(List<String> arguments,
      {String? script, RunOptions? runOptions, String? workingDirectory}) {
    runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
    activate();

    return Pub.global.run(packageName,
        script: script, arguments: arguments, runOptions: runOptions);
  }

  @override
  Future<String> runAsync(List<String> arguments,
      {String? script, RunOptions? runOptions}) {
    activate();

    return Pub.global.runAsync(packageName,
        script: script, arguments: arguments, runOptions: runOptions);
  }
}

class _PubLocalApp extends PubApp {
  _PubLocalApp(super.packageName) : super._();

  @override
  bool get isGlobal => false;

  // TODO: Implement: call a `Pub.isActivated/Pub.isInstalled`.
  @override
  bool get isActivated => throw UnsupportedError('unimplemented');

  @override
  void activate({bool force = false}) {}

  @override
  String run(List<String> arguments,
      {String? script, RunOptions? runOptions, String? workingDirectory}) {
    runOptions = mergeWorkingDirectory(workingDirectory, runOptions);
    return Pub.run(packageName,
        script: script, arguments: arguments, runOptions: runOptions);
  }

  @override
  Future<String> runAsync(List<String> arguments,
      {String? script, RunOptions? runOptions}) {
    return Pub.runAsync(packageName,
        script: script, arguments: arguments, runOptions: runOptions);
  }
}
