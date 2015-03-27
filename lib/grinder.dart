// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/**
 * A task based, dependency aware build system.
 *
 * See the [README][] for detailed usage information.
 *
 * [README]: https://pub.dartlang.org/packages/grinder
 */
library grinder;

export 'grinder_files.dart';
export 'grinder_tools.dart';
export 'src/cli.dart' show grinderArgs;

import 'dart:async';
import 'dart:mirrors';

import 'src/discover_tasks.dart';
import 'src/cli.dart';
import 'src/singleton.dart';

/// Used to define a method body for a task. Note: a task's context is now
/// available as a global variable ('context'). Your task functions should no
/// longer be definied with a single `GrinderContext` parameter.
typedef dynamic TaskFunction(GrinderContext context);

/// Programmatically add a [task] to the global [Grinder] instance.
///
/// Any calls to this should occur before the call to [grind].
void addTask(GrinderTask task) => grinder.addTask(task);

/// The default task run when no tasks are specified on the command line.
GrinderTask get defaultTask => grinder.defaultTask;

set defaultTask(GrinderTask v) {
  grinder.defaultTask = v;
}

/**
 * Add a new task definition to the global [Grinder] instance. A [name] is
 * required. If specified, a [taskFunction] is invoked when the task starts.
 * Any dependencies of the task, that need to run before it, should be passed
 * in via [depends].
 */
@Deprecated('Use the task annotations instead.')
void task(String name, [Function taskFunction, List<String> depends = const []]) {
  grinder.addTask(
      new GrinderTask(name, taskFunction: taskFunction, depends: depends));
}

/// Run the grinder file.
///
/// First, discovers the tasks declared in your grinder file.  Then, handles
/// the command-line [args] either by running tasks or responding to
/// recognized options such as --help.
///
/// If a task fails, throw a [GrinderException], runs no further tasks, and
/// exits with a non-zero exit code.
Future grind(List<String> args) => new Future(() {
  discoverTasks(grinder, currentMirrorSystem().isolate.rootLibrary);
  return handleArgs(args);
});

/**
 * Start the build process. This should be called at the end of the `main()`
 * method. If there is a task failure, this method will halt task execution and
 * throw a [GrinderException].
 */
@Deprecated('Use `grind` instead.')
Future startGrinder(List<String> args) {
  return handleArgs(args);
}

// Zone variables.

/// Get the [GrinderContext] for the currently executing task.
GrinderContext get context => zonedContext.value;

/// Log an informational message to Grinder's output.
void log(String message) => context.log(message);

/// Halt task execution; throws an exception with the given error message.
void fail(String message) => context.fail(message);

/**
 * A [GrinderContext] is used to give the currently running Grinder task the
 * ability to introspect the running state. It can get the current [Grinder]
 * instance and get a reference to the current [GrinderTask] instance (as well as
 * the previous and next tasks, if any).
 *
 * A [GrinderContext] also allows you to log messages and errors.
 */
class GrinderContext {
  /// The [Grinder] instance.
  final Grinder grinder;
  /// The current running [GrinderTask].
  final GrinderTask task;

  GrinderContext._(this.grinder, this.task);

  /// Log an informational message to Grinder's output.
  void log(String message) {
    List lines = message.trimRight().split('\n');
    lines = lines.expand((line) {
      final int len = 120;
      if (line.length > len) {
        List results = [];
        results.add(line.substring(0, len));
        line = line.substring(len);
        while (line.length > len) {
          results.add('  ${line.substring(0, len)}');
          line = line.substring(len);
        }
        if (line.isNotEmpty) results.add('  ${line}');
        return results;
      } else {
        return [line];
      }
    }).toList();
    grinder.log("  ${lines.join('\n  ')}");
  }

  /// Halt task execution; throws an exception with the given error message.
  void fail(String message) {
    log('');
    log('failed: ${message}');
    log('      : ${_getLocation()}');

    throw new _FailException(message);
  }

  String toString() => "Context for ${task}";
}

/// Represents a Grinder task. These can be created automatically using the
/// [Task] and [Depends] annotations.
class GrinderTask {
  /// The name of the task.
  final String name;
  /// The function to execute when starting this task.
  final Function taskFunction;
  /// The list of task dependencies; tasks that must run before this task should
  /// execute.
  final List<String> depends;
  /// An optional description of the task.
  final String description;

  /**
   * Create a new [GrinderTask]. A name is required; a [description], [run] to
   * execute when this task is started, and a [depends] list are optional.
   */
  GrinderTask(this.name,
      {this.taskFunction, this.depends : const [], this.description});

  /**
   * This method is invoked when the task is started. If a task was created with
   * a [Function], that function will be invoked by this method.
   */
  dynamic execute(GrinderContext _context) {
    if (taskFunction == null) return null;

    if (taskFunction is TaskFunction) {
      return zonedContext.withValue(_context, () {
        return taskFunction(context);
      });
    } else {
      return zonedContext.withValue(_context, taskFunction);
    }
  }

  String toString() => "[${name}]";
}

/// An annotation to mark a [GrinderTask] definition.
///
/// In your grinder entry point file, place this on top-levels which are either
/// [Function] methods or properties which return [Function]s.
///
/// Task dependencies can be defined with a co-located [Depends] annotation.
class Task {
  /// See [GrinderTask.description].
  final String description;

  const Task([this.description]);
}

/// An annotation to define a [Task]'s dependencies.
///
/// Each listed dependency can be either a:
/// * link to a [Function] which is also annotated as a [Task]. Useful for
///   rename refactoring, finding uses, etc.
/// * [String]. Useful for referring to programmatically added tasks.
class Depends {
  final dep1;
  final dep2;
  final dep3;
  final dep4;
  final dep5;
  final dep6;
  final dep7;
  final dep8;

  const Depends(this.dep1, [this.dep2, this.dep3, this.dep4, this.dep5,
      this.dep6, this.dep7, this.dep8]);

  List get depends => [dep1, dep2, dep3, dep4, dep5, dep6, dep7, dep8]
      .takeWhile((dep) => dep != null)
      .toList();
}

/**
 * An annotation to define the default [GrinderTask] to run when no tasks are
 * specified on the command line.
 *
 * Use this instead of [Task] when defining the default task.
 */
class DefaultTask extends Task {
  const DefaultTask([String description])
      : super(description);
}

/**
 * A class representing a running instance of a Grinder.
 */
class Grinder {
  List<GrinderTask> _tasks = [];
  Map<GrinderTask, List> _taskDeps;
  List<GrinderTask> _calcedTasks = [];
  Set<String> _calcedTaskNameSet = new Set();

  /// Create a new instance of Grinder.
  Grinder();

  /// Add a task to this Grinder instance.
  void addTask(GrinderTask task) => _tasks.add(task);

  /// The default task run when no tasks are specified on the command line.
  GrinderTask get defaultTask => _defaultTask;

  set defaultTask(GrinderTask v) {
    // TODO: Throw when overwriting an existing default task?
    addTask(v);
    _defaultTask = v;
  }

  GrinderTask _defaultTask;

  /// Get the list of all the Grinder tasks.
  List<GrinderTask> get tasks => _tasks;

  /// Get the task with the given name. Returns `null` if none found.
  GrinderTask getTask(String name) =>
      _tasks.firstWhere((t) => t.name == name, orElse: () => null);

  /// Return the calculated build order of the tasks for this run.
  List<GrinderTask> getBuildOrder() {
    return _calcedTasks;
  }

  void _postOrder(GrinderTask task) {
    for (String dependName in task.depends) {
      _postOrder(getTask(dependName));
    }
    if (!_calcedTaskNameSet.contains(task.name)) {
      _calcedTaskNameSet.add(task.name);
      _calcedTasks.add(task);
    }
  }

  /**
   * Start the build process and run all the tasks in the calculated build
   * order.
   *
   * [start] should be called once and only once; i.e., Grinder instances are
   * not re-usable.
   *
   * The [dontRun] parameter can be used to audit the grinder file, without
   * actually executing any targets.
   *
   * Throws [GrinderException] if named tasks don't exist, or there are
   * cycles in the dependency graph.
   */
  Future start(List<String> targets, {bool dontRun: false}) {
    if (_taskDeps != null) {
      throw new StateError("Grinder instances are not re-usable");
    }

    DateTime startTime = new DateTime.now();

    if (targets.isEmpty) {
      if (defaultTask != null) {
        targets = [defaultTask.name];
      } else {
        log('no tasks specified, and no default task defined');
      }
      log('run `grinder -h` for help and a list of valid tasks');
      if (targets.isEmpty) return new Future.value();
    }

    // Verify that all named tasks exist.
    for (String taskName in targets) {
      if (getTask(taskName) == null) {
        throw new GrinderException("task '${taskName}' doesn't exist");
      }
    }

    // Verify that there aren't any duplicate names.
    Set<String> names = new Set();

    for (GrinderTask task in _tasks) {
      if (names.contains(task.name)) {
        throw new GrinderException("task '${task.name}' is defined twice");
      }
      names.add(task.name);
    }

    // Verify that all referenced tasks exist.
    for (GrinderTask task in tasks) {
      for (String name in task.depends) {
        if (getTask(name) == null) {
          throw new GrinderException(
              "task '${name}' referenced by ${task}, doesn't exist");
        }
      }
    }

    _calculateAllDeps();

    // Verify that there are no dependency cycles.
    for (GrinderTask task in tasks) {
      if (getAllDependencies(task).contains(task)) {
        throw new GrinderException("Task ${task} has a dependency cycle.\n"
            "  ${task} ==> ${getAllDependencies(task).join(', ')}");
      }
    }

    for (String taskName in targets) {
      _postOrder(getTask(taskName));
    }

    if (!dontRun) {
      log('grinder running ${_calcedTasks.join(' ')}');
      log('');

      return Future.forEach(_calcedTasks, (GrinderTask task) {
        return _executeTask(task);
      }).then((_) {
        Duration elapsed = new DateTime.now().difference(startTime);
        log('finished in ${elapsed.inMilliseconds / 1000.0} seconds.');
      }).catchError((e, st) {
        if (e is! _FailException) {
          return new Future.error(e, st);
        }
      });
    } else {
      return new Future.value();
    }
  }

  /// Given a task, return all of its immediate dependencies.
  Iterable<GrinderTask> getImmediateDependencies(GrinderTask task) {
    return task.depends.map((name) => getTask(name));
  }

  /// Given a task, return all of its transitive dependencies.
  List<GrinderTask> getAllDependencies(GrinderTask task) => _taskDeps[task];

  /// Log the given informational message.
  void log(String message) => print(message);

  Future _executeTask(GrinderTask task) {
    log('${task}');

    GrinderContext context = new GrinderContext._(this, task);
    var result = task.execute(context);

    if (!(result is Future)) {
      result = new Future.value(result);
    }

    // TODO: whenComplete(), dispose of the context?
    return (result as Future).then((_) {
      log('');
    });
  }

  void _calculateAllDeps() {
    _taskDeps = new Map();

    for (GrinderTask task in _tasks) {
      _taskDeps[task] = _calcDependencies(task, new Set()).toList();
    }
  }

  Set<GrinderTask> _calcDependencies(GrinderTask task, Set<GrinderTask> foundTasks) {
    for (GrinderTask childTask in getImmediateDependencies(task)) {
      bool contains = foundTasks.contains(childTask);
      foundTasks.add(childTask);
      if (!contains) {
        _calcDependencies(childTask, foundTasks);
      }
    }
    return foundTasks;
  }
}

/**
 * An exception class for the Grinder library.
 */
class GrinderException implements Exception {
  /// A message describing the error.
  final String message;

  /// Create a new `GrinderException`.
  GrinderException(this.message);

  String toString() => "GrinderException: ${message}";
}

class _FailException extends GrinderException {
  _FailException(String message) : super(message);
}

String _getLocation() {
  try {
    throw 'foo';
  } catch (e, st) {
    List<String> lines = '${st}'.split('\n');
    if (lines.length < 3) {
      return null;
    }
    String line = lines[2];
    if (line.length > 5 && line[4] == ' ') {
      line = line.substring(4);
    }
    return line.trim().replaceAll('<anonymous closure>', '<anon>');
  }
}
