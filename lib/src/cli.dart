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
const String APP_VERSION = '0.6.6+3';

List<String> grinderArgs() => _args;
List<String> _args;

Future handleArgs(List<String> args) {
  _args = args == null ? [] : args;

  ArgParser parser = createArgsParser();
  ArgResults results = parser.parse(grinderArgs());

  if (results['version']) {
    const String pubUrl = 'https://pub.dartlang.org/packages/grinder.json';

    print('grinder version ${APP_VERSION}');

    return httpGet(pubUrl).then((String str) {
      List versions = JSON.decode(str)['versions'];
      if (APP_VERSION != versions.last) {
        print("Version ${versions.last} is available! Run `pub global activate"
            " grinder` to get the latest version.");
      } else {
        print('grinder is up to date!');
      }
    }).catchError((e) => null);
  } else if (results['help']) {
    printUsage(parser, grinder);
  } else if (results['deps']) {
    printDeps(grinder);
  } else {
    Future result = grinder.start(results.rest);

    return result.catchError((e, st) {
      if (st != null) {
        print('\n${e}\n${st}');
      } else {
        print('\n${e}');
      }
      exit(1);
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
  parser.addFlag('deps', abbr: 'd', negatable: false,
      help: "display the dependencies of targets");
  return parser;
}

void printUsage(ArgParser parser, Grinder grinder) {
  print('usage: dart ${currentScript()} <options> target1 target2 ...');
  print('');
  print('valid options:');
  print(parser.usage.replaceAll('\n\n', '\n'));

  if (!grinder.tasks.isEmpty) {
    print('');
    print('valid targets:');

    List<GrinderTask> tasks = grinder.tasks.toList();
    tasks.forEach((t) {
      var buffer = new StringBuffer()..write('  $t');
      if (grinder.defaultTask == t) buffer.write(' (default)');
      if (t.description != null) buffer.write(' ${t.description}');
      print(buffer.toString());
    });
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

void printDeps(Grinder grinder) {
  // calculate the dependencies
  grinder.start([], dontRun: true);

  if (grinder.tasks.isEmpty) {
    print("no grinder targets defined");
  } else {
    print('grinder targets:');
    print('');

    List<GrinderTask> tasks = grinder.tasks.toList();
    tasks.forEach((GrinderTask t) {
      t.description == null ? print("${t}") : print("  ${t} ${t.description}");

      if (!grinder.getImmediateDependencies(t).isEmpty) {
        print("  ${grinder.getAllDependencies(t).join(', ')}");
      }
    });
  }
}
