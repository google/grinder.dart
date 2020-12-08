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
const String appVersion = '0.8.5';

List<String> grinderArgs() {
  var args = _args;
  if (args == null) fail('grinderArgs() may only be called after grind().');
  return args;
}

List<String>? _args;

Future runTasks(
  List<String> args, {
  bool verifyProjectRoot = false,
}) async {
  _args = args;

  final parser = ArgParser(
    'grinder',
    'Dart workflows, automated.',
    () => getTaskHelp(singleton.grinder),
  );

  parser.addFlag('color',
      negatable: true, help: 'Whether to use terminal colors.');
  parser.addFlag('version', help: 'Reports the version of this tool.');
  parser.addFlag('help', abbr: 'h', help: 'Print this usage information.');

  final results = parser.parse(args);

  if (results.getFlag('help')) {
    print(parser.getUsage());
    return null;
  } else if (results.getFlag('version')) {
    print('grinder version ${appVersion}');
    return null;
  } else {
    if (results.hasFlag('color')) {
      singleton.grinder.ansi = Ansi(results.getFlag('color'));
    } else {
      singleton.grinder.ansi = Ansi(true);
    }

    if (verifyProjectRoot) {
      // Verify that we're running from the project root.
      if (!getFile('pubspec.yaml').existsSync()) {
        fail('This script must be run from the project root.');
      }
    }

    for (final invocation in results.taskInvocations) {
      var task = singleton.grinder.getTask(invocation.name);
      if (task == null) fail("Error, no task found: '${invocation.name}'.");
    }

    final result = singleton.grinder.start(results.taskInvocations);

    return result.catchError((e, st) {
      fail('\n${e}\n${cleanupStackTrace(st)}');
    });
  }
}

typedef DescribeFunction = String Function();

class ArgParser {
  final String name;
  final String description;

  final DescribeFunction _describeTasks;
  final List<_ArgsFlag> _flags = [];

  ArgParser(this.name, this.description, DescribeFunction describeTasks)
      : _describeTasks = describeTasks;

  void addFlag(String name,
      {String? abbr, String? help, bool negatable = false}) {
    _flags.add(_ArgsFlag(name, abbr: abbr, help: help, negatable: negatable));
  }

  ArgResults parse(List<String> args) {
    final results = ArgResults._(args);

    String? taskInvocation;
    List<String>? taskArgs;

    for (final arg in args) {
      if (arg.startsWith('-')) {
        // in flags, or args for a task
        if (taskInvocation != null) {
          if (taskArgs == null) {
            fail('Arg "$arg" must come after a task name.');
          } else {
            taskArgs.add(arg);
          }
        } else {
          if (arg.startsWith('--')) {
            results._flags.add(arg.substring(2));
          } else {
            final abbr = arg.substring(1);
            for (final flag in _flags) {
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
          results.taskInvocations.add(TaskInvocation(
              taskInvocation, TaskArgs(taskInvocation, taskArgs!)));
        }

        taskInvocation = arg;
        taskArgs = [];
      }
    }

    if (taskInvocation != null) {
      results.taskInvocations.add(
          TaskInvocation(taskInvocation, TaskArgs(taskInvocation, taskArgs!)));
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
  final String? abbr;
  final String? help;
  final bool negatable;

  _ArgsFlag(this.name, {this.abbr, this.help, this.negatable = false});

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
  final Set<String> _flags = <String>{};

  ArgResults._(this.arguments);

  bool hasFlag(String name) => _flags.contains(name);

  bool getFlag(String name) => _flags.contains(name);

  @override
  String toString() => arguments.join(' ');
}
