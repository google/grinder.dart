// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.task_invocation;

import 'package:collection/collection.dart';

/// An invocation of a [GrinderTask].
///
/// Identifies the [name] of the task to invoke, and any [arguments] to send to
/// it.
class TaskInvocation {
  final String name;
  TaskArgs _arguments;

  TaskInvocation(this.name, [TaskArgs arguments]) {
    _arguments = arguments ?? new TaskArgs(this.name, const []);
  }

  TaskArgs get arguments => _arguments;

  bool operator ==(other) =>
      other is TaskInvocation &&
      name == other.name &&
      const IterableEquality()
          .equals(arguments.arguments, other.arguments.arguments);

  int get hashCode =>
      name.hashCode ^ (const IterableEquality().hash(arguments.arguments) * 3);

  String toString() {
    var args = arguments.arguments;
    var argString = args.isEmpty ? '' : ':${args.join(',')}';
    return '[$name$argString]';
  }
}

/// Any arguments passed into the task from the command line.
///
/// The arguments could be in the form of flags (`grind foo --release`) or flags
/// (`grind foo --config=bar`).
class TaskArgs {
  final String taskName;

  /// The original list of arguments that were parsed.
  final List<String> arguments;

  final Map<String, bool> _flags = {};
  final Map<String, String> _options = {};

  TaskArgs(this.taskName, this.arguments) {
    _parse();
  }

  bool hasFlag(String name) => _flags.containsKey(name);

  bool getFlag(String name) => hasFlag(name) ? _flags[name] : false;

  bool hasOption(String name) => _options.containsKey(name);

  String getOption(String name) => _options[name];

  void _parse() {
    for (String arg in arguments) {
      if (!arg.startsWith('--')) continue;

      if (arg.contains('=')) {
        // handle options
        arg = arg.substring(2);

        String name = arg.substring(0, arg.indexOf('='));
        String value = arg.substring(arg.indexOf('=') + 1);

        if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        }

        _options[name] = value;
      } else {
        // handle flags
        arg = arg.substring(2);

        if (arg.startsWith('no-')) {
          arg = arg.substring(3);
          _flags[arg] = false;
        } else {
          _flags[arg] = true;
        }
      }
    }
  }
}
