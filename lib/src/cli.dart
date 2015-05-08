// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.cli;

import 'dart:async';
import 'dart:convert' show JSON, UTF8;
import 'dart:math';

import 'package:ansicolor/ansicolor.dart';
import 'package:unscripted/unscripted.dart';

import 'singleton.dart' as singleton;
import 'utils.dart';
import '../grinder.dart';

// This version must be updated in tandem with the pubspec version.
const String APP_VERSION = '0.7.0';

List<String> grinderArgs() => _args;
List<String> _args;
bool _verifyProjectRoot;

Future handleArgs(List<String> args, {bool verifyProjectRoot}) {
  _args = args == null ? [] : args;
  _verifyProjectRoot = verifyProjectRoot;
  return script.execute(grinderArgs());
}

// TODO: Re-inline this variable once the fix for http://dartbug.com/23354
//       is released.
const _completion = const Completion();
@Command(help: 'Dart workflows, automated.', plugins: const [_completion])
cli(
    @Rest(help: getTaskHelp, allowed: allowedTasks)
    List<String> tasks,
    {
     @Flag(help: 'Print the version of grinder.', defaultsTo: false)
     bool version,
     @Option(help: 'Set the location of the Dart SDK.')
     String dartSdk,
     @Deprecated('Task dependencies are now available via --help.')
     @Flag(hide:true, abbr: 'd', defaultsTo: false,
         help: 'Display the dependencies of tasks.')
     bool deps
    }) {

  if (version) {
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
  } else if (tasks.isEmpty && !singleton.grinder.hasDefaultTask) {
    // Support this directly in `unscripted`.
    print('No default task defined.');
    return script.execute(['-h']);
  } else {
    if (_verifyProjectRoot) {
      // Verify that we're running from the project root.
      if (!getFile('pubspec.yaml').existsSync()) {
        fail('This script must be run from the project root.');
      }
    }

    Future result = singleton.grinder.start(tasks);

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

var script = new Script(cli);


String getTaskHelp({Grinder grinder, bool useColor}) {
  if (grinder == null) grinder = singleton.grinder;

  var positionalPen = new AnsiPen()..green();
  var textPen = new AnsiPen()..gray(level: 0.5);

  var originalColorDisabled = color_disabled;
  if (useColor != null) color_disabled = !useColor;

  if (grinder.tasks.isEmpty) {
    return '\n\n  No tasks defined.\n';
  }

  // Calculate the dependencies.
  grinder.start([], dontRun: true);

  List<GrinderTask> tasks = grinder.tasks.toList();

  var firstColMap = tasks.fold({}, (map, task) {
    map[task] = '$task${grinder.defaultTask == task ? ' (default)' : ''}';
    return map;
  });

  var firstColMax = firstColMap.values.fold(0, (width, next) => max(width, next.length));
  var padding = 4;
  var firstColWidth = firstColMax + padding;

  var ret = '\n\n' + tasks.map((GrinderTask task) {
    Iterable<GrinderTask> deps = grinder.getImmediateDependencies(task);

    var buffer = new StringBuffer();
    buffer.write('  ${positionalPen(firstColMap[task].padRight(firstColWidth))}');
    var desc = task.description == null ? '' : task.description;
    var depText = '${textPen('(depends on ')}${positionalPen(deps.join(' '))}${textPen(')')}';
    if (desc.isNotEmpty) {
      buffer.writeln(textPen(task.description));
      if (deps.isNotEmpty) {
        buffer.writeln('  ${''.padRight(firstColWidth)}$depText');
      }
    } else {
      if (deps.isNotEmpty) buffer.write(depText);
      buffer.writeln();
    }

    return buffer.toString();
  }).join();

  if (useColor != null) color_disabled = originalColorDisabled;

  return ret;
}

List<String> allowedTasks() =>
    singleton.grinder.tasks.map((task) => task.name).toList();

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
