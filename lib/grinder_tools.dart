// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/**
 * Commonly used tools for build scripts, including for tasks like running the
 * `pub` commands.
 */
library grinder.tools;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cli_util/cli_util.dart' as cli_util;
import 'package:which/which.dart';

import 'grinder.dart';
import 'src/utils.dart';
import 'src/_mserve.dart';
import 'src/_wip.dart';

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
 *
 * This is an alias for the `cli_util` package's `getSdkDir()` method.
 */
Directory getSdkDir([List<String> cliArgs]) => cli_util.getSdkDir(cliArgs);

File get dartVM => joinFile(sdkDir, ['bin', _sdkBin('dart')]);

/**
 * Run the given Dart script in a new process.
 */
String runDartScript(String script,
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

  return runProcess(_sdkBin('dart'), arguments: args, quiet: quiet,
      workingDirectory: workingDirectory);
}

/// Run the given [executable], with optional [arguments] and [workingDirectory].
///
/// Returns the stdout.
String runProcess(String executable,
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
    throw new ProcessException(executable, result.exitCode, result.stderr);
  }

  return result.stdout;
}

/// Run the given [executable], with optional [arguments] and [workingDirectory].
///
/// Returns a future for the stdout.
Future<String> runProcessAsync(String executable,
    {List<String> arguments : const [],
     bool quiet: false,
     String workingDirectory}) {

  if (!quiet) log("$executable ${arguments.join(' ')}");

  List<int> stdout = [], stderr = [];

  return Process.start(executable, arguments, workingDirectory: workingDirectory)
      .then((Process process) {

    // Handle stdout.
    var broadcastStdout = process.stdout.asBroadcastStream();
    var stdoutLines = _toLineStream(broadcastStdout);
    broadcastStdout.listen((List<int> data) => stdout.addAll(data));
    if (!quiet) {
      stdoutLines.listen(_logStdout);
    }

    // Handle stderr.
    var broadcastStderr = process.stderr.asBroadcastStream();
    var stderrLines = _toLineStream(broadcastStderr);
    broadcastStderr.listen((List<int> data) => stderr.addAll(data));
    stderrLines.listen(_logStderr);

    return process.exitCode.then((int code) {
      if (code != 0) {
        throw new ProcessException(executable, code, SYSTEM_ENCODING.decode(stderr));
      }

      return SYSTEM_ENCODING.decode(stdout);
    });
  });
}

/// A default implementation of an `init` task. This task verifies that the
/// grind script is executed from the project root.
@Deprecated('the functionality of this method has been rolled into grinder startup')
void defaultInit([GrinderContext context]) { }

/// A default implementation of a `clean` task. This task deletes all generated
/// artifacts in the `build/`.
void defaultClean([GrinderContext context]) => delete(BUILD_DIR);

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
  static String get({bool force: false, String workingDirectory}) {
    FileSet pubspec = new FileSet.fromFile(new File('pubspec.yaml'));
    FileSet publock = new FileSet.fromFile(new File('pubspec.lock'));

    if (force || !publock.upToDate(pubspec)) {
      return _run('get', workingDirectory: workingDirectory);
    }

    return null;
  }

  /**
   * Run `pub get` on the current project. If [force] is true, this will execute
   * even if the pubspec.lock file is up-to-date with respect to the
   * pubspec.yaml file.
   */
  static Future<String> getAsync({bool force: false, String workingDirectory}) {
    FileSet pubspec = new FileSet.fromFile(new File('pubspec.yaml'));
    FileSet publock = new FileSet.fromFile(new File('pubspec.lock'));

    if (force || !publock.upToDate(pubspec)) {
      return runProcessAsync(_sdkBin('pub'), arguments: ['get'],
          workingDirectory: workingDirectory);
    }

    return new Future.value();
  }

  /**
   * Run `pub upgrade` on the current project.
   */
  static String upgrade({String workingDirectory}) {
    return _run('upgrade', workingDirectory: workingDirectory);
  }

  /**
   * Run `pub upgrade` on the current project.
   */
  static Future<String> upgradeAsync({String workingDirectory}) {
    return runProcessAsync(_sdkBin('pub'), arguments: ['upgrade'],
        workingDirectory: workingDirectory);
  }

  /**
   * Run `pub build` on the current project.
   *
   * The valid values for [mode] are `release` and `debug`.
   */
  static String build({
      String mode,
      List<String> directories,
      String workingDirectory,
      String outputDirectory}) {
    List args = ['build'];
    if (mode != null) args.add('--mode=${mode}');
    if (outputDirectory != null) args.add('--output=${outputDirectory}');
    if (directories != null && directories.isNotEmpty) args.addAll(directories);

    return runProcess(_sdkBin('pub'), arguments: args,
        workingDirectory: workingDirectory);
  }

  /**
   * Run `pub build` on the current project.
   *
   * The valid values for [mode] are `release` and `debug`.
   */
  static Future<String> buildAsync({
      String mode,
      List<String> directories,
      String workingDirectory,
      String outputDirectory}) {
    List args = ['build'];
    if (mode != null) args.add('--mode=${mode}');
    if (outputDirectory != null) args.add('--output=${outputDirectory}');
    if (directories != null && directories.isNotEmpty) args.addAll(directories);

    return runProcessAsync(_sdkBin('pub'), arguments: args,
        workingDirectory: workingDirectory);
  }

  /// Run `pub run` on the given [package] and [script].
  ///
  /// If [script] is null it defaults to the same value as [package].
  static void run(String package, {List<String> arguments, String workingDirectory,
      String script}) {
    var scriptArg = script == null ? package : '$package:$script';
    List args = ['run', scriptArg];
    if (arguments != null) args.addAll(arguments);
    runProcess(_sdkBin('pub'), arguments: args,
        workingDirectory: workingDirectory);
  }

  static String version({bool quiet: false}) => AppVersion.parse(
      _run('--version', quiet: quiet)).version;

  static PubGlobal get global => _global;

  static String _run(String command, {bool quiet: false, String workingDirectory}) {
    return runProcess(_sdkBin('pub'), quiet: quiet, arguments: [command],
        workingDirectory: workingDirectory);
  }
}

/// Access the `pub global` commands.
class PubGlobal {
  PubGlobal._();

  /// Install a new Dart application.
  String activate(String package) =>
      runProcess(_sdkBin('pub'), arguments: ['global', 'activate', package]);

  /// Run the given installed Dart application.
  String run(String package, {List<String> arguments, String workingDirectory}) {
    List args = ['global', 'run', package];
    if (arguments != null) args.addAll(arguments);
    return runProcess(_sdkBin('pub'), arguments: args,
        workingDirectory: workingDirectory);
  }

  /// Return the list of installed applications.
  List<AppVersion> list() {
    //dart_coveralls 0.1.8
    //den 0.1.3
    //discoveryapis_generator 0.6.1
    //...

    var stdout = runProcess(_sdkBin('pub'), arguments: ['global', 'list'], quiet: true);

    var lines = stdout.trim().split('\n');
    return lines.map((line) {
      line = line.trim();
      if (!line.contains(' ')) return new AppVersion._(line);
      var parts = line.split(' ');
      return new AppVersion._(parts.first, parts[1]);
    }).toList();
  }

  /// Returns whether the given Dart application is installed.
  bool isInstalled(String packageName) {
    return list().any((AppVersion app) => app.name == packageName);
  }
}

/// A Dart command-line application, installed via `pub global activate`.
class PubApplication {
  final String appName;

  bool _installed = false;

  /// Create a new reference to a pub application; [appName] is the same as the
  /// package name.
  PubApplication(this.appName);

  bool isInstalled() {
    if (_installed) return true;
    _installed = Pub.global.isInstalled(appName);
    return _installed;
  }

  /// Install the application (run `pub global activate`).
  ProcessResult activate() {
    if (!_installed) {
      var result = Pub.global.activate(appName);
      _installed = true;
      return result;
    }
    return null;
  }

  /// Run the application. If the application is not installed this command will
  /// first activate it.
  String run(List<String> arguments, {String workingDirectory}) {
    if (!_installed && !isInstalled()) activate();
    return Pub.global.run(appName, arguments: arguments,
        workingDirectory: workingDirectory);
  }

  /// Install the application or update it to the lastest version.
  ProcessResult update() {
    var result = Pub.global.activate(appName);
    _installed = true;
    return result;
  }

  String toString() => appName;
}

/**
 * Utility tasks for invoking dart2js.
 */
class Dart2js {
  /**
   * Invoke a dart2js compile with the given [sourceFile] as input.
   */
  static String compile(File sourceFile,
      {Directory outDir, bool minify: false, bool csp: false}) {
    if (outDir == null) outDir = sourceFile.parent;
    File outFile = joinFile(outDir, ["${fileName(sourceFile)}.js"]);

    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    List args = [];
    if (minify) args.add('--minify');
    if (csp) args.add('--csp');
    args.add('-o${outFile.path}');
    args.add(sourceFile.path);

    return runProcess(_sdkBin('dart2js'), arguments: args);
  }

  /**
   * Invoke a dart2js compile with the given [sourceFile] as input.
   */
  static Future<String> compileAsync(File sourceFile,
      {Directory outDir, bool minify: false, bool csp: false}) {
    if (outDir == null) outDir = sourceFile.parent;
    File outFile = joinFile(outDir, ["${fileName(sourceFile)}.js"]);

    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    List args = [];
    if (minify) args.add('--minify');
    if (csp) args.add('--csp');
    args.add('-o${outFile.path}');
    args.add(sourceFile.path);

    return runProcessAsync(_sdkBin('dart2js'), arguments: args);
  }

  static String version({bool quiet: false}) =>
      AppVersion.parse(_run('--version', quiet: quiet)).version;

  static String _run(String command, {bool quiet: false}) =>
      runProcess(_sdkBin('dart2js'), quiet: quiet, arguments: [command]);
}

/**
 * Utility tasks for invoking the analyzer.
 */
class Analyzer {
  /// Analyze a single [File] or path ([String]).
  static String analyze(fileOrPath,
      {Directory packageRoot, bool fatalWarnings: false}) {
    return analyzeFiles([fileOrPath], packageRoot: packageRoot,
        fatalWarnings: fatalWarnings);
  }

  /// Analyze one or more [File]s or paths ([String]).
  static String analyzeFiles(List files,
      {Directory packageRoot, bool fatalWarnings: false}) {
    List args = [];
    if (packageRoot != null) args.add('--package-root=${packageRoot.path}');
    if (fatalWarnings) args.add('--fatal-warnings');
    args.addAll(files.map((f) => f is File ? f.path : f));

    return runProcess(_sdkBin('dartanalyzer'), arguments: args);
  }

  static String version({bool quiet: false}) => AppVersion.parse(runProcess(
      _sdkBin('dartanalyzer'), quiet: quiet, arguments: ['--version'])).version;
}

/**
 * A utility class to run tests for your project.
 */
class Tests {
  /**
   * Run command-line tests. You can specify the base directory (`test`), and
   * the file to run (`all.dart`).
   */
  static String runCliTests({String directory: 'test', String testFile: 'all.dart'}) {
    String file = '${directory}/${testFile}';
    log('running tests: ${file}...');
    return runDartScript(file);
  }

  /**
   * Run web tests in a browser instance. You can specify the base directory
   * (`test`), and the html file to run (`index.html`).
   */
  static Future runWebTests({String directory: 'test',
       String htmlFile: 'index.html',
       Chrome browser}) {
    // Choose a random port to tell the browser to serve debug info to. If we
    // specify a fixed port the browser may fail to connect, but we'll still try
    // and create a debug connection to the port.
    int wip = 33000 + new math.Random().nextInt(10000); //9222;

    if (browser == null) {
      if (directory.startsWith('build')) {
        browser = Chrome.getBestInstalledChrome();
      } else {
        browser = Chrome.getBestInstalledChrome(preferDartium: true);
      }
    }

    if (browser == null) {
      return new Future.error('Unable to locate a Chrome install');
    }

    MicroServer server;
    BrowserInstance browserInstance;
    String url;
    ChromeTab tab;
    WipConnection connection;

    // Start a server.
    return MicroServer.start(port: 0, path: directory).then((s) {
      server = s;

      log("microserver serving '${server.path}' on ${server.urlBase}");

      // Start the browser.
      log('opening ${browser.browserPath}');

      List<String> args = ['--remote-debugging-port=${wip}'];
      if (Platform.environment['CHROME_ARGS'] != null) {
       args.addAll(Platform.environment['CHROME_ARGS'].split(' '));
      }
      url = 'http://${server.host}:${server.port}/${htmlFile}';
      return browser.launchUrl(url, args: args);
    }).then((bi) {
      browserInstance = bi;

      // Find tab.
      return new ChromeConnection(server.host, wip).getTab((tab) {
        return tab.url == url || tab.url.endsWith(htmlFile);
      }, retryFor: new Duration(seconds: 5));
    }).then((t) {
      tab = t;

      log('connected to ${tab}');

      // Connect via WIP.
      return WipConnection.connect(tab.webSocketDebuggerUrl);
    }).then((c) {
      connection = c;
      connection.console.enable();
      StreamSubscription sub;
      ResettableTimer timer;

      var teardown = () {
        sub.cancel();
        connection.close();
        browserInstance.kill();
        server.destroy();
        timer.cancel();
      };

      Completer completer = new Completer();

      timer = new ResettableTimer(new Duration(seconds: 60), () {
        teardown();
        if (!completer.isCompleted) {
          completer.completeError('tests timed out');
        }
      });

      sub = connection.console.onMessage.listen(
          (ConsoleMessageEvent event) {
        timer.reset();
        log(event.text);

        // 'tests finished - passed' or 'tests finished - failed'.
        if (event.text.contains('tests finished -')) {
          teardown();

          if (event.text.contains('tests finished - failed')) {
            completer.completeError('tests failed');
          } else {
            completer.complete();
          }
        }
      });

      return completer.future;
    });
  }
}

class Chrome {
  static Chrome getBestInstalledChrome({bool preferDartium: false}) {
    Chrome chrome;

    if (preferDartium) {
      chrome = new Dartium();
      if (chrome.exists) return chrome;
    }

    chrome = new Chrome.createChromeStable();
    if (chrome.exists) return chrome;

    chrome = new Chrome.createChromeDev();
    if (chrome.exists) return chrome;

    chrome = new Chrome.createChromium();
    if (chrome.exists) return chrome;

    if (!preferDartium) {
      chrome = new Dartium();
      if (chrome.exists) return chrome;
    }

    return null;
  }

  final String browserPath;
  Directory _tempDir;

  Chrome(this.browserPath) {
    _tempDir = Directory.systemTemp.createTempSync('userDataDir-');
  }

  Chrome.createChromeStable() : this(_chromeStablePath());
  Chrome.createChromeDev() : this(_chromeDevPath());
  Chrome.createChromium() : this(_chromiumPath());

  bool get exists => new File(browserPath).existsSync();

  void launchFile(String filePath, {bool verbose: false, Map envVars}) {
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
    log("starting chrome...");
    runProcess(browserPath, arguments: args, environment: envVars);
  }

  Future<BrowserInstance> launchUrl(String url,
      {List<String> args, bool verbose: false, Map envVars}) {
    List<String> _args = [
        '--no-default-browser-check',
        '--no-first-run',
        '--user-data-dir=${_tempDir.path}'
    ];

    if (verbose) _args.addAll(['--enable-logging=stderr', '--v=1']);
    if (args != null) _args.addAll(args);

    _args.add(url);

    return Process.start(browserPath, _args, environment: envVars)
        .then((Process process) {
      // Handle stdout.
      var stdoutLines = _toLineStream(process.stdout);
      stdoutLines.listen(_logStdout);

      // Handle stderr.
      var stderrLines = _toLineStream(process.stderr);
      stderrLines.listen(_logStderr);

      return new BrowserInstance(this, process);
    });
  }
}

class BrowserInstance {
  final Chrome browser;
  final Process process;

  int _exitCode;

  BrowserInstance(this.browser, this.process) {
    process.exitCode.then((int code) {
      _exitCode = code;
    });
  }

  int get exitCode => _exitCode;

  bool get running => _exitCode != null;

  void kill() {
    process.kill();
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

bool _sdkOnPath;

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

  path = whichSync('Dartium', orElse: () => null);

  return path;
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

String _chromiumPath() {
  if (Platform.isLinux) {
    return '/usr/bin/chromium-browser';
  } else if (Platform.isMacOS) {
    return '/Applications/Chromium.app/Contents/MacOS/Chromium';
  }

  return null;
}

/// A version/app name pair.
class AppVersion {
  final String name;
  final String version;

  AppVersion._(this.name, [this.version]);

  static AppVersion parse(String output) {
    var lastSpace = output.lastIndexOf(' ');
    if (lastSpace == -1) return new AppVersion._(output);
    return new AppVersion._(output.substring(0, lastSpace),
        output.substring(lastSpace + 1));
  }

  String toString() => '$name $version';
}

/// An exception from a process which exited with a non-zero exit code.
class ProcessException {
  final String executable;
  final int exitCode;
  final String stderr;

  ProcessException(this.executable, this.exitCode, this.stderr);

  String toString() => """
$executable failed with exit code $exitCode and stderr:
$stderr""";
}

Stream<String> _toLineStream(Stream<List<int>> s) =>
    s.transform(UTF8.decoder).transform(const LineSplitter());

_logStdout(String line) {
  log(line);
}

_logStderr(String line) {
  log('stderr: $line');
}
