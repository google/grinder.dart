// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/**
 * Commonly used tools for build scripts, including for tasks like running the
 * `pub` commands.
 */
library grinder.tools;

import 'dart:async';
import 'dart:io';

import 'package:which/which.dart';

import 'grinder.dart';

final Directory BIN_DIR = new Directory('bin');
final Directory BUILD_DIR = new Directory('build');
final Directory LIB_DIR = new Directory('lib');
final Directory WEB_DIR = new Directory('web');

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
 */
Directory getSdkDir([List<String> cliArgs]) {
  // Look for --dart-sdk on the command line.
  if (cliArgs != null) {
    int index = cliArgs.indexOf('--dart-sdk');

    if (index != -1 && (index + 1 < cliArgs.length)) {
      return new Directory(cliArgs[index + 1]);
    }

    for (String arg in cliArgs) {
      if (arg.startsWith('--dart-sdk=')) {
        return new Directory(arg.substring('--dart-sdk='.length));
      }
    }
  }

  // Look in env['DART_SDK']
  if (Platform.environment['DART_SDK'] != null) {
    return new Directory(Platform.environment['DART_SDK']);
  }

  // Look relative to the dart executable.
  Directory sdkDirectory = new File(Platform.executable).parent.parent;
  if (_isSdkDir(sdkDirectory)) return sdkDirectory;

  // Try and locate the VM using 'which'.
  String executable = whichSync('dart', orElse: () => null);

  // In case Dart is symlinked (e.g. homebrew on Mac) follow symbolic links.
  Link link = new Link(executable);
  if (link.existsSync()) {
    executable = link.resolveSymbolicLinksSync();
  }

  File dartVm = new File(executable);
  Directory dir = dartVm.parent.parent;
  if (_isSdkDir(dir)) return dir;

  return null;
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
     String workingDirectory,
     Map<String, String> environment}) {
  context.log("${executable} ${arguments.join(' ')}");

  ProcessResult result = Process.runSync(
      executable, arguments, workingDirectory: workingDirectory,
      environment: environment);

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
 * A default implementation of an `init` task. This task verifies that the grind
 * script is executed from the project root.
 */
void defaultInit(GrinderContext context) {
  // Verify that we're running in the project root.
  if (!getFile('pubspec.yaml').existsSync()) {
    context.fail('This script must be run from the project root.');
  }
}

/**
 * A default implementation of a `clean` task. This task deletes all generated
 * artifacts in the `build/`.
 */
void defaultClean(GrinderContext context) {
  // Delete the `build/` dir.
  deleteEntity(BUILD_DIR, context);
}

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
  static void get(GrinderContext context,
      {bool force: false, String workingDirectory}) {
    FileSet pubspec = new FileSet.fromFile(new File('pubspec.yaml'));
    FileSet publock = new FileSet.fromFile(new File('pubspec.lock'));

    if (force || !publock.upToDate(pubspec)) {
      _run(context, _execName('get'), workingDirectory: workingDirectory);
    }
  }

  /**
   * Run `pub get` on the current project. If [force] is true, this will execute
   * even if the pubspec.lock file is up-to-date with respect to the
   * pubspec.yaml file.
   */
  static Future getAsync(GrinderContext context,
      {bool force: false, String workingDirectory}) {
    FileSet pubspec = new FileSet.fromFile(new File('pubspec.yaml'));
    FileSet publock = new FileSet.fromFile(new File('pubspec.lock'));

    if (force || !publock.upToDate(pubspec)) {
      return runProcessAsync(context, _execName('pub'), arguments: ['get'],
          workingDirectory: workingDirectory);
    } else {
      return new Future.value();
    }
  }

  /**
   * Run `pub upgrade` on the current project.
   */
  static void upgrade(GrinderContext context, {String workingDirectory}) {
    _run(context, 'upgrade', workingDirectory: workingDirectory);
  }

  /**
   * Run `pub upgrade` on the current project.
   */
  static Future upgradeAsync(GrinderContext context, {String workingDirectory}) {
    return runProcessAsync(context, _execName('pub'), arguments: ['upgrade'],
        workingDirectory: workingDirectory);
  }

  /**
   * Run `pub build` on the current project.
   *
   * The valid values for [mode] are `release` and `debug`.
   */
  static void build(GrinderContext context,
      {String mode, List<String> directories, String workingDirectory,
       String outputDirectory}) {
    List args = ['build'];
    if (mode != null) args.add('--mode=${mode}');
    if (outputDirectory != null) args.add('--output=${outputDirectory}');
    if (directories != null && directories.isNotEmpty) args.addAll(directories);

    runProcess(context, _execName('pub'), arguments: args,
        workingDirectory: workingDirectory);
  }

  /**
   * Run `pub build` on the current project.
   *
   * The valid values for [mode] are `release` and `debug`.
   */
  static Future buildAsync(GrinderContext context,
      {String mode, List<String> directories, String workingDirectory,
       String outputDirectory}) {
    List args = ['build'];
    if (mode != null) args.add('--mode=${mode}');
    if (outputDirectory != null) args.add('--output=${outputDirectory}');
    if (directories != null && directories.isNotEmpty) args.addAll(directories);

    return runProcessAsync(context, _execName('pub'), arguments: args,
        workingDirectory: workingDirectory);
  }

  static void version(GrinderContext context) => _run(context, '--version');

  static PubGlobal get global => _global;

  static void _run(GrinderContext context, String command,
      {String workingDirectory}) {
    runProcess(context, _execName('pub'), arguments: [command],
        workingDirectory: workingDirectory);
  }
}

class PubGlobal {
  PubGlobal._();

  void activate(GrinderContext context, String package) {
    runProcess(context, _execName('pub'),
        arguments: ['global', 'activate', package]);
  }

  void run(GrinderContext context, String package,
      {List<String> arguments, String workingDirectory}) {
    List args = ['global', 'run', package];
    if (arguments != null) args.addAll(arguments);
    runProcess(context, _execName('pub'), arguments: args,
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
  static void compile(GrinderContext context, File sourceFile,
      {Directory outDir, bool minify: false, bool csp: false}) {
    if (outDir == null) outDir = sourceFile.parent;
    File outFile = joinFile(outDir, ["${fileName(sourceFile)}.js"]);

    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    List args = [];
    if (minify) args.add('--minify');
    if (csp) args.add('--csp');
    args.add('-o${outFile.path}');
    args.add(sourceFile.path);

    runProcess(context, _execName('dart2js'), arguments: args);
  }

  /**
   * Invoke a dart2js compile with the given [sourceFile] as input.
   */
  static Future compileAsync(GrinderContext context, File sourceFile,
      {Directory outDir, bool minify: false, bool csp: false}) {
    if (outDir == null) outDir = sourceFile.parent;
    File outFile = joinFile(outDir, ["${fileName(sourceFile)}.js"]);

    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    List args = [];
    if (minify) args.add('--minify');
    if (csp) args.add('--csp');
    args.add('-o${outFile.path}');
    args.add(sourceFile.path);

    return runProcessAsync(context, _execName('dart2js'), arguments: args);
  }

  static void version(GrinderContext context) => _run(context, '--version');

  static void _run(GrinderContext context, String command) {
    runProcess(context, _execName('dart2js'), arguments: [command]);
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

    runProcess(context, _execName('dartanalyzer'), arguments: args);
  }

  static void version(GrinderContext context) =>
      runProcess(context, _execName('dartanalyzer'), arguments: ['--version']);
}

/**
 * A utility class to run tests for your project.
 */
class Tests {
  /**
   * Run command-line tests in the `test` directory. If no parameters are passed
   * for [paths], this method defaults to running the `test/all.dart` script.
   */
  static void runCliTests(GrinderContext context, [List<String> paths]) {
    if (paths == null) {
      paths = ['all.dart'];
    }

    for (String path in paths) {
      String testFile = 'test/${path}';
      context.log('running tests ${testFile}...');
      runDartScript(context, testFile);
    }
  }

  // TODO: specify dartium in web/, or chrome in build/web

//  /**
//   * TODO: doc
//   */
//  static void runWebTests(GrinderContext context, [List<String> paths]) {
//    // TODO: we'll need to locate content_shell
//
//  }
}

class Chrome {
  final String browserPath;
  Directory _tempDir;

  Chrome(this.browserPath) {
    _tempDir = Directory.systemTemp.createTempSync('userDataDir-');
  }

  Chrome.createChromeStable() : this(_chromeStablePath());
  Chrome.createChromeDev() : this(_chromeDevPath());

  bool get exists => new File(browserPath).existsSync();

  void launchFile(GrinderContext context, String filePath,
      {bool verbose: false, Map envVars}) {
    String url;

    if (new File(filePath).existsSync()) {
      url = 'file:/' + new Directory(filePath).absolute.path;
    } else {
      url = filePath;
    }

    List<String> args = [
        '--no-default-browser-check',
        '--no-first-run',
        '--user-data-dir=${_tempDir.path}'
    ];

    if (verbose) {
      args.addAll(['--enable-logging=stderr', '--v=1']);
    }

    args.add(url);

    // TODO: This process often won't terminate, so that's a problem.
    context.log("starting chrome...");
    runProcess(context, browserPath, arguments: args, environment: envVars);
  }
}

/**
 * A wrapper around the Dartium browser.
 */
class Dartium extends Chrome {
  Dartium() : super(_dartiumPath());
}

class ContentShell extends Chrome {
  static String _contentShellPath() {
    final Map m = {
      "linux": "content_shell/content_shell",
      "macos": "content_shell/Content Shell.app/Contents/MacOS/Content Shell",
      "windows": "content_shell/content_shell.exe"
    };

    String sep = Platform.pathSeparator;
    String os = Platform.operatingSystem;
    String dartSdkPath = sdkDir.path;

    // Truncate any trailing /'s.
    if (dartSdkPath.endsWith(sep)) {
      dartSdkPath = dartSdkPath.substring(0, dartSdkPath.length - 1);
    }

    String path = "${dartSdkPath}${sep}..${sep}chromium${sep}${m[os]}";

    if (FileSystemEntity.isFileSync(path)) {
      return new File(path).absolute.path;
    }

    return null;
  }

  ContentShell() : super(_contentShellPath());
}

String _execName(String name) {
  if (Platform.isWindows) {
    return name == 'dart' ? 'dart.exe' : '${name}.bat';
  }

  return name;
}

String _dartiumPath() {
  final Map m = {
    "linux": "chrome",
    "macos": "Chromium.app/Contents/MacOS/Chromium",
    "windows": "chrome.exe"
  };

  String sep = Platform.pathSeparator;
  String os = Platform.operatingSystem;
  String dartSdkPath = sdkDir.path;

  // Truncate any trailing /'s.
  if (dartSdkPath.endsWith(sep)) {
    dartSdkPath = dartSdkPath.substring(0, dartSdkPath.length - 1);
  }

  String path = "${dartSdkPath}${sep}..${sep}chromium${sep}${m[os]}";

  if (FileSystemEntity.isFileSync(path)) {
    return new File(path).absolute.path;
  }

  return null;
}

String _chromeStablePath() {
  if (Platform.isLinux) {
    return '/usr/bin/google-chrome';
  } else if (Platform.isMacOS) {
    return '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
  } else {
    List paths = [
      r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
      r"C:\Program Files\Google\Chrome\Application\chrome.exe"
    ];

    for (String path in paths) {
      if (new File(path).existsSync()) {
        return path;
      }
    }
  }

  return null;
}

String _chromeDevPath() {
  if (Platform.isLinux) {
    return '/usr/bin/google-chrome-unstable';
  } else if (Platform.isMacOS) {
    return '/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary';
  } else {
    return null;
  }
}

bool _isSdkDir(Directory dir) => joinFile(dir, ['version']).existsSync();
