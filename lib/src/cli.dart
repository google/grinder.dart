// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.cli;

import 'dart:async';

import 'package:cli_util/cli_logging.dart' show Ansi;
import 'package:grinder/src/utils.dart';

import '../grinder.dart';
import 'cli_util.dart';
import 'singleton.dart' as singleton;

// This version must be updated in tandem with the pubspec version.
const String appVersion = '0.8.1-dev';

List<String> grinderArgs() => _args;
List<String> _args;
bool _verifyProjectRoot;

Future runTasks(
  List<String> args, {
  bool verifyProjectRoot: false,
}) async {
  _args = args == null ? [] : args;
  _verifyProjectRoot = verifyProjectRoot;

  final ArgParser parser = new ArgParser(
    'grinder',
    'Dart workflows, automated.',
    () => getTaskHelp(singleton.grinder),
  );

  parser.addFlag('color',
      negatable: true, help: 'Whether to use terminal colors.');
  parser.addFlag('version', help: 'Reports the version of this tool.');
  parser.addFlag('help', abbr: 'h', help: 'Print this usage information.');

  final ArgResults results = parser.parse(args);

  if (results.getFlag('help')) {
    print(parser.getUsage());
    return null;
  } else if (results.getFlag('version')) {
    print('grinder version ${appVersion}');
    return null;
  } else {
    if (results.hasFlag('color')) {
      singleton.grinder.ansi = new Ansi(results.getFlag('color'));
    } else {
      singleton.grinder.ansi = new Ansi(true);
    }

    if (_verifyProjectRoot) {
      // Verify that we're running from the project root.
      if (!getFile('pubspec.yaml').existsSync()) {
        fail('This script must be run from the project root.');
      }
    }

    for (TaskInvocation invocation in results.taskInvocations) {
      var task = singleton.grinder.getTask(invocation.name);
      if (task == null) fail("Error, no task found: '${invocation.name}'.");
    }

    Future result = singleton.grinder.start(results.taskInvocations);

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
}

typedef String DescribeFunction();

class ArgParser {
  final String name;
  final String description;

  DescribeFunction _describeTasks;
  final List<_ArgsFlag> _flags = [];

  ArgParser(this.name, this.description, DescribeFunction describeTasks) {
    this._describeTasks = describeTasks;
  }

  void addFlag(String name, {String abbr, String help, bool negatable: false}) {
    _flags
        .add(new _ArgsFlag(name, abbr: abbr, help: help, negatable: negatable));
  }

  ArgResults parse(List<String> args) {
    ArgResults results = new ArgResults._(args);

    String taskInvocation;
    List<String> taskArgs;

    for (String arg in args) {
      if (arg.startsWith('-')) {
        // in flags, or args for a task
        if (taskInvocation != null) {
          taskArgs.add(arg);
        } else {
          if (arg.startsWith('--')) {
            results._flags.add(arg.substring(2));
          } else {
            String abbr = arg.substring(1);
            for (_ArgsFlag flag in _flags) {
              if (flag.abbr == abbr) {
                results._flags.add(flag.name);
                break;
              }
            }
          }
        }
      } else {
        // start a new task
        if (taskInvocation != null) {
          results.taskInvocations.add(new TaskInvocation(
              taskInvocation, new TaskArgs(taskInvocation, taskArgs)));
        }

        taskInvocation = arg;
        taskArgs = [];
      }
    }

    if (taskInvocation != null) {
      results.taskInvocations.add(new TaskInvocation(
          taskInvocation, new TaskArgs(taskInvocation, taskArgs)));
    }

    return results;
  }

  String getUsage() {
    return '''
$description

Usage: $name [options] [<tasks>...]

Global options:
${_flagsHelp()}

Available tasks:
${_describeTasks()}
''';
  }

  String _flagsHelp() {
    return _flags.map((_ArgsFlag flag) {
      return '  ${flag.label.padRight(20)} ${flag.help ?? ''}';
    }).join('\n');
  }
}

class _ArgsFlag {
  final String name;
  final String abbr;
  final String help;
  final bool negatable;

  _ArgsFlag(this.name, {this.abbr, this.help, this.negatable});

  String get label {
    if (negatable) {
      return '--no-$name';
    } else {
      return abbr == null ? '--$name' : '-$abbr, --$name';
    }
  }
}

class ArgResults {
  /// The raw list of arguments.
  final List<String> arguments;

  final List<TaskInvocation> taskInvocations = [];
  final Set<String> _flags = new Set();

  ArgResults._(this.arguments);

  bool hasFlag(String name) => _flags.contains(name);

  bool getFlag(String name) => _flags.contains(name);

  String toString() => arguments.join(' ');
}
