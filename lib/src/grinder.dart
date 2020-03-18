// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.grinder;

import 'dart:async';

import 'package:cli_util/cli_logging.dart' show Ansi;

import 'grinder_context.dart';
import 'grinder_exception.dart';
import 'grinder_task.dart';
import 'singleton.dart';
import 'task_invocation.dart';

/// Programmatically add a [task] to the global [Grinder] instance.
///
/// Any calls to this should occur before the call to [grind].
void addTask(GrinderTask task) => grinder.addTask(task);

/// The default task run when no tasks are specified on the command line.
GrinderTask get defaultTask => grinder.defaultTask;

set defaultTask(GrinderTask v) {
  grinder.defaultTask = v;
}

/// A class representing a running instance of a Grinder.
class Grinder {
  final List<GrinderTask> _tasks = [];
  Map<GrinderTask, List> _taskDeps;
  final List<TaskInvocation> _invocationOrder = [];
  final Set<String> _calcedTaskNameSet = <String>{};

  Ansi ansi = Ansi(Ansi.terminalSupportsAnsi);

  /// Create a new instance of Grinder.
  Grinder();

  /// Add a task to this Grinder instance.
  void addTask(GrinderTask task) => _tasks.add(task);

  /// The default task run when no tasks are specified on the command line.
  GrinderTask get defaultTask => _defaultTask;

  set defaultTask(GrinderTask v) {
    if (_defaultTask != null) {
      throw GrinderException('Cannot overwrite existing default task '
          '$_defaultTask with task $v.');
    }
    addTask(v);
    _defaultTask = v;
  }

  /// Return whether this grinder instance has a default task set.
  bool get hasDefaultTask => _defaultTask != null;

  GrinderTask _defaultTask;

  /// Get the list of all the Grinder tasks.
  List<GrinderTask> get tasks => _tasks;

  /// Get the task with the given name. Returns `null` if none found.
  GrinderTask getTask(String name) =>
      _tasks.firstWhere((t) => t.name == name, orElse: () => null);

  /// Return the calculated build order of the task invocations for this run.
  List<TaskInvocation> getBuildOrder() => _invocationOrder;

  void _postOrder(TaskInvocation invocation) {
    var task = getTask(invocation.name);
    for (var dep in task.depends) {
      _postOrder(dep);
    }

    if (!_calcedTaskNameSet.contains(invocation.name)) {
      _calcedTaskNameSet.add(invocation.name);
      _invocationOrder.add(invocation);
    } else {
      var existing = _invocationOrder
          .firstWhere((existing) => existing.name == invocation.name);
      if (invocation != existing) {
        throw GrinderException(
            'Cannot run a task multiple times with different arguments.');
      }
    }
  }

  /// Start the build process and run all the tasks in the calculated build
  /// order.
  ///
  /// [start] should be called once and only once; i.e., Grinder instances are
  /// not re-usable.
  ///
  /// Items in [invocations] can either be [String] names of tasks to invoke, or
  /// full [TaskInvocation]s.
  ///
  /// The [dontRun] parameter can be used to audit the grinder file, without
  /// actually executing any targets.
  ///
  /// Throws [GrinderException] if named tasks don't exist, or there are
  /// cycles in the dependency graph.
  Future start(Iterable invocations, {bool dontRun = false}) {
    if (!dontRun && _taskDeps != null) {
      throw StateError('Grinder instances are not re-usable');
    }

    invocations = invocations.map((invocation) =>
        invocation is String ? TaskInvocation(invocation) : invocation);

    final startTime = DateTime.now();

    if (invocations.isEmpty) {
      if (defaultTask != null) {
        invocations = [TaskInvocation(defaultTask.name)];
      } else if (!dontRun) {
        throw GrinderException('Tried to call non-existent default task.');
      }
      if (invocations.isEmpty) return Future.value();
    }

    // Verify that all named tasks exist.
    for (var invocation in invocations) {
      var name = invocation.name;
      if (getTask(name) == null) {
        throw GrinderException("task '$name' doesn't exist");
      }
    }

    // Verify that there aren't any duplicate names.
    final names = <String>{};

    for (final task in _tasks) {
      if (names.contains(task.name)) {
        throw GrinderException("task '${task.name}' is defined twice");
      }
      names.add(task.name);
    }

    // Verify that all referenced tasks exist.
    for (final task in tasks) {
      for (var invocation in task.depends) {
        if (getTask(invocation.name) == null) {
          throw GrinderException(
              "task '${invocation.name}' referenced by ${task}, doesn't exist");
        }
      }
    }

    _calculateAllDeps();

    // Verify that there are no dependency cycles.
    for (final task in tasks) {
      if (getAllDependencies(task)
          .any((invocation) => invocation.name == task.name)) {
        throw GrinderException('Task ${task} has a dependency cycle.\n'
            "  ${task} ==> ${getAllDependencies(task).join(', ')}");
      }
    }

    invocations.forEach((i) => _postOrder(i as TaskInvocation));

    if (!dontRun) {
      log('grinder running ${_invocationOrder.join(' ')}');
      log('');

      return Future.forEach(_invocationOrder, (TaskInvocation task) {
        return _invokeTask(task);
      }).then((_) {
        final elapsed = DateTime.now().difference(startTime);
        log('finished in ${(elapsed.inMilliseconds ~/ 100) / 10} seconds');
      });
    } else {
      return Future.value();
    }
  }

  /// Given a task, return all of its immediate dependencies.
  Iterable<TaskInvocation> getImmediateDependencies(GrinderTask task) =>
      task.depends;

  /// Given a task, return all of its transitive dependencies.
  List<TaskInvocation> getAllDependencies(GrinderTask task) => _taskDeps[task];

  /// Log the given informational message.
  void log(String message) => print(message);

  Future _invokeTask(TaskInvocation invocation) {
    log('${ansi.emphasized(invocation.toString())}');

    var task = getTask(invocation.name);
    final context = GrinderContext(this, task, invocation);
    dynamic result = task.execute(context, invocation.arguments);

    if (result is! Future) {
      result = Future.value(result);
    }

    return (result as Future).then((_) {
      log('');
    });
  }

  void _calculateAllDeps() {
    _taskDeps = {};

    for (final task in _tasks) {
      _taskDeps[task] = _calcDependencies(task, {}).toList();
    }
  }

  Set<TaskInvocation> _calcDependencies(
      GrinderTask task, Set<TaskInvocation> foundDeps) {
    for (var dep in getImmediateDependencies(task)) {
      final contains = foundDeps.contains(dep);
      foundDeps.add(dep);
      if (!contains) {
        _calcDependencies(getTask(dep.name), foundDeps);
      }
    }
    return foundDeps;
  }
}
