// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.cli;

import 'dart:async';
import 'dart:convert' show JSON, UTF8;
import 'dart:io';

import 'package:args/args.dart';

import 'singleton.dart';
import 'utils.dart';
import '../grinder.dart';

// This version must be updated in tandem with the pubspec version.
const String APP_VERSION = '0.7.0';

List<String> grinderArgs() => _args;
List<String> _args;

Future handleArgs(List<String> args, {bool verifyProjectRoot: true}) {
  _args = args == null ? [] : args;

  ArgParser parser = createArgsParser();
  ArgResults results = parser.parse(grinderArgs());

  if (results['version']) {
    const String pubUrl = 'https://pub.dartlang.org/packages/grinder.json';

    log('grinder version ${APP_VERSION}');

    return httpGet(pubUrl).then((String str) {
      List versions = JSON.decode(str)['versions'];
      if (APP_VERSION != versions.last) {
        log("Version ${versions.last} is available! Run `pub global activate"
            " grinder` to get the latest version.");
      } else {
        log('grinder is up to date!');
      }
    }).catchError((e) => null);
  } else if (results['help'] || results['deps']) {
    // TODO: Remove `deps` options post 0.7.0.
    printUsageAndDeps(parser, grinder);
  } else if (results.rest.isEmpty && !grinder.hasDefaultTask){
    printUsageAndDeps(parser, grinder);
  } else {
    if (verifyProjectRoot) {
      // Verify that we're running from the project root.
      if (!getFile('pubspec.yaml').existsSync()) {
        fail('This script must be run from the project root.');
      }
    }

    Future result = grinder.start(results.rest);

    return result.catchError((e, st) {
      String message;
      if (st != null) {
        message = '\n${e}\n${cleanupStackTrace(st)}';
      } else {
        message = '\n${e}';
      }
      fail(message);
    });
  }

  return new Future.value();
}

ArgParser createArgsParser() {
  ArgParser parser = new ArgParser();
  parser.addOption('dart-sdk',
      help: 'set the location of the Dart SDK');
  parser.addFlag('version', negatable: false,
      help: "print the version of grinder");
  parser.addFlag('help', abbr: 'h', negatable: false,
      help: "show targets but don't build");
  // TODO: Deprecated; remove post 0.7.0.
  parser.addFlag('deps', abbr: 'd', negatable: false, hide: true,
      help: "display the dependencies of targets");
  return parser;
}

void printUsageAndDeps(ArgParser parser, Grinder grinder) {
  log('usage: dart ${currentScript()} <options> target1 target2 ...');
  log('');
  log('valid options:');
  log(parser.usage.replaceAll('\n\n', '\n'));

  if (grinder.tasks.isEmpty) {
    log('');
    log('no current grinder targets');
  } else {
    // calculate the dependencies
    grinder.start([], dontRun: true);

    log('');
    log('targets:');

    List<GrinderTask> tasks = grinder.tasks.toList();
    log(tasks.map((task) {
      bool isDefault = grinder.defaultTask == task;
      Iterable<GrinderTask> deps = grinder.getImmediateDependencies(task);

      String str = '  ${task}${isDefault ? ' (default)' : ''}\n';
      if (task.description != null) str += '    ${task.description}\n';
      if (deps.isNotEmpty) str += '    depends on: ${deps.map((t) => t.toString()).join(' ')}\n';
      return str;
    }).join());
  }
}

String currentScript() {
  String script = Platform.script.toString();
  String uriBase = Uri.base.toString();
  if (script.startsWith(uriBase)) {
    script = script.substring(uriBase.length);
  }
  return script;
}

String cleanupStackTrace(st) {
  List<String> lines = '${st}'.trim().split('\n');

  // Remove lines which are not useful to debugging script issues. With our move
  // to using zones, the exceptions now have stacks 30 frames deep.
  while (lines.isNotEmpty) {
    String line = lines.last;

    if (line.contains(' (dart:') || line.contains(' (package:grinder/')) {
      lines.removeLast();
    } else {
      break;
    }
  }

  return lines.join('\n').trim().replaceAll('<anonymous closure>', '<anon>');
}
