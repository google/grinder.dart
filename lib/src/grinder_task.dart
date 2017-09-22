// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.grinder_task;

import 'dart:collection';

import 'package:unscripted/unscripted.dart';

import 'grinder_context.dart';
import 'grinder_exception.dart';
import 'singleton.dart';
import 'task_invocation.dart';

/// Represents a Grinder task. These can be created automatically using the
/// [Task] and [Depends] annotations.
class GrinderTask {
  /// The name of the task.
  final String name;

  /// The function to execute when starting this task.
  final Function taskFunction;

  /// The list of task invocation dependencies; task invocations that must run
  /// before this task is invoked.
  final List<TaskInvocation> depends;

  /// An optional description of the task.
  final String description;

  /// The list of positional task parameters.
  final List<Positional> positionals;

  /// The list of positional task parameters.
  final Rest rest;

  /// The list of named task parameters ([Option]s and [Flag]s).
  final Iterable<Option> options;

  /// Create a new [GrinderTask].
  ///
  /// Items in [depends] represent task dependencies.  They can either be
  /// [String] names of tasks (without arguments), or full [TaskInvocation]s.
  ///
  /// Use [positionals], [rest], and [options] to define parameters accepted by
  /// this task.
  GrinderTask(this.name,
      {this.taskFunction,
      this.description,
      Iterable depends: const [],
      Iterable<Positional> positionals: const [],
      this.rest,
      Iterable<Option> options: const []})
      : this.depends = new UnmodifiableListView(depends
            .map((dep) => dep is String ? new TaskInvocation(dep) : dep)),
        this.positionals = new UnmodifiableListView(positionals.toList()),
        this.options = new UnmodifiableListView(options.toList()) {
    if (taskFunction == null && depends.isEmpty) {
      throw new GrinderException('GrinderTasks must have a task function or '
          'dependencies.');
    }
  }

  /**
   * This method is invoked when the task is started. If a task was created with
   * a [Function], that function will be invoked by this method.
   */
  dynamic execute(GrinderContext _context) {
    if (taskFunction == null) return null;

    var f = taskFunction is _TaskFunction
        ? () => taskFunction(context)
        : taskFunction;

    return zonedContext.withValue(_context, f);
  }

  String toString() => "[${name}]";
}

// Temporary internal version of `TaskFunction`.
// TODO: Remove this when removing the ability to use such functions.
typedef dynamic _TaskFunction(GrinderContext context);
