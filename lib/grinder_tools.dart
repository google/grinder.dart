// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/// Commonly used tools for build scripts.
library grinder.tools;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';
import 'package:which/which.dart';

import 'grinder.dart';
import 'src/run.dart' as run_lib;
import 'src/run_utils.dart';
import 'src/utils.dart';
import 'src/_mserve.dart';

export 'src/run.dart';

final Directory binDir = new Directory('bin');
final Directory buildDir = new Directory('build');
final Directory libDir = new Directory('lib');
final Directory webDir = new Directory('web');

@Deprecated('See binDir') Directory get BIN_DIR => binDir;
@Deprecated('See buildDir') Directory get BUILD_DIR => buildDir;
@Deprecated('See libDir') Directory get LIB_DIR => libDir;
@Deprecated('See webDir') Directory get WEB_DIR => webDir;

/// Run a dart [script] using [run_lib.run].
///
/// Returns the stdout.
@Deprecated('Use `Dart.run` instead.')
String runDartScript(String script,
    {List<String> arguments : const [], bool quiet: false, String packageRoot,
    RunOptions runOptions, int vmNewGenHeapMB, int vmOldGenHeapMB,
    @Deprecated('Use RunOptions.workingDirectory instead.')
    String workingDirectory}) {
  runOptions = mergeRunOptions(workingDirectory, runOptions);
  return Dart.run(
      script,
      arguments: arguments,
      quiet: quiet,
      packageRoot: packageRoot,
      runOptions: runOptions,
      vmNewGenHeapMB: vmNewGenHeapMB,
      vmOldGenHeapMB: vmOldGenHeapMB);
}

/// A default implementation of an `init` task. This task verifies that the
/// grind script is executed from the project root.
@Deprecated('the functionality of this method has been rolled into grinder startup')
void defaultInit([GrinderContext context]) { }

/// A default implementation of a `clean` task. This task deletes all generated
/// artifacts in the `build/`.
void defaultClean([GrinderContext context]) => delete(buildDir);

/**
 * A utility class to run tests for your project.
 */
class Tests {
  /**
   * Run command-line tests. You can specify the base directory (`test`), and
   * the file to run (`all.dart`).
   */
  static void runCliTests({String directory: 'test', String testFile: 'all.dart'}) {
    String file = '${directory}/${testFile}';
    log('running tests: ${file}...');
    Dart.run(file);
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
    run_lib.run(browserPath, arguments: args, runOptions: new RunOptions(environment: envVars));
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
      var stdoutLines = toLineStream(process.stdout);
      stdoutLines.listen(logStdout);

      // Handle stderr.
      var stderrLines = toLineStream(process.stderr);
      stderrLines.listen(logStderr);

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
