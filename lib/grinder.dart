// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/**
 * A library and tool to drive a command-line build.
 *
 * Grinder build files are entirely specified in Dart code. This allows you to
 * write and debug your build files with the same tools you use for the rest of
 * your project source.
 *
 * Generally, a Grinder implementation will look something like this:
 *     void main([List<String> args]) {
 *       task('init', init);
 *       task('compile', compile, ['init']);
 *       task('deploy', deploy, ['compile']);
 *       task('docs', deploy, ['init']);
 *       task('all', ['deploy', 'docs']);
 *
 *       startGrinder(args);
 *     }
 *
 *     init(GrinderContext context) {
 *       context.log("I set things up");
 *     }
 *
 *     ...
 *
 * Tasks to run are specified on the command line. If a task has dependencies,
 * those dependent tasks are run before the specified task.
 *
 * ## Command-line usage
 *     usage: dart grinder.dart <options> target1 target2 ...
 *
 *     valid options:
 *     --version     print the version of grinder
 *     -h, --help    show targets but don't build
 *     -d, --deps    display the dependencies of targets
 */
library grinder;

export 'grinder_files.dart';
export 'grinder_tools.dart';

import 'dart:async';
import 'dart:convert' show JSON, UTF8;
import 'dart:io';

import 'package:args/args.dart';

final Grinder _grinder = new Grinder();
List<String> _args;

// This version must be updated in tandem with the pubspec version.
const String _APP_VERSION = '0.6.5';

/**
 * Used to define a method body for a task.
 */
typedef dynamic TaskFunction(GrinderContext context);

List<String> grinderArgs() => _args;

/**
 * Add a new task to the global [Grinder] instance. Some combination of this
 * and [task] should be called before [startGrinder] is invoked.
 */
void addTask(GrinderTask task) => _grinder.addTask(task);

/**
 * Add a new task definition to the global [Grinder] instance. A [name] is
 * required. If specified, a [taskFunction] is invoked when the task starts.
 * Any dependencies of the task, that need to run before it, should be passed
 * in via [depends].
 */
void task(String name, [TaskFunction taskFunction, List<String> depends = const []]) {
  _grinder.addTask(
      new GrinderTask(name, taskFunction: taskFunction, depends: depends));
}

/**
 * Start the build process. This should be called at the end of the `main()`
 * method. If there is a task failure, this method will halt task execution and
 * throw a [GrinderException].
 *
 * [startGrinder] should be called once and only once.
 */
Future startGrinder(List<String> args) {
  _args = args == null ? [] : args;

  ArgParser parser = _createArgsParser();
  ArgResults results = parser.parse(grinderArgs());

  if (results['version']) {
    const String pubUrl = 'https://pub.dartlang.org/packages/grinder.json';

    print('grinder version ${_APP_VERSION}');

    HttpClient client = new HttpClient();
    return client.getUrl(Uri.parse(pubUrl)).then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) {
      return response.toList();
    }).then((List<List> data) {
      String str = UTF8.decode(data.reduce((a, b) => a.addAll(b)));
      List versions = JSON.decode(str)['versions'];
      if (_APP_VERSION != versions.last) {
        print("Version ${versions.last} is available! Run `pub global activate"
             " grinder` to get the latest.");
      } else {
        print('grinder is up to date!');
      }
    }).catchError((e) => null);
  } else if (results['help']) {
    _printUsage(parser, _grinder);
  } else if (results['deps']) {
    _printDeps(_grinder);
  } else if (results.rest.isEmpty) {
    _printUsage(parser, _grinder);
  } else {
    Future result = _grinder.start(results.rest);

    return result.catchError((e, st) {
      print('${e}\n${st}');
      exit(1);
    });
  }

  return new Future.value();
}

// args handling

ArgParser _createArgsParser() {
  ArgParser parser = new ArgParser();
  parser.addFlag('version', negatable: false,
      help: "print the version of grinder");
  parser.addFlag('help', abbr: 'h', negatable: false,
      help: "show targets but don't build");
  parser.addFlag('deps', abbr: 'd', negatable: false,
      help: "display the dependencies of targets");
  return parser;
}

void _printUsage(ArgParser parser, Grinder grinder) {
  print('usage: dart ${_currentScript()} <options> target1 target2 ...');
  print('');
  print('valid options:');
  print(parser.usage.replaceAll('\n\n', '\n'));

  if (!grinder.tasks.isEmpty) {
    print('');
    print('valid targets:');

    List<GrinderTask> tasks = grinder.tasks.toList();
    tasks.forEach(
        (t) => t.description == null ? print("  ${t}") : print("  ${t} ${t.description}"));
  }
}

String _currentScript() {
  String script = Platform.script.toString();
  String uriBase = Uri.base.toString();
  if (script.startsWith(uriBase)) {
    script = script.substring(uriBase.length);
  }
  return script;
}

void _printDeps(Grinder grinder) {
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

/**
 * A [GrinderContext] is used to given the currently running Grinder task the
 * ability to introspect the running state. It can get the get the current
 * [Grinder] instance and get a reference to the current [GrinderTask] instance
 * as well as the previous and next tasks, if any.
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
  void log(String message) => grinder.log("  ${message.replaceAll('\n', '\n  ')}");

  /// Halt task execution; throws an exception with the given error message.
  void fail(String message) {
    log('');
    log('failed: ${message}');
    log('      : ${_getLocation()}');
    throw new _FailException(message);
  }

  String toString() => "Context for ${task}";
}

/**
 * This class represents a Grinder task. These are created automatically by
 * the [task] function.
 */
class GrinderTask {
  /// The name of the task.
  final String name;
  /// The function to execute when starting this task.
  final TaskFunction taskFunction;
  /// The list of task dependencies; tasks that must run before this task should
  /// execute.
  final List<String> depends;
  /// An optional description of the task.
  final String description;

  /**
   * Create a new [GrinderTask]. A name is required; a [description],
   * [run] to execute when this task is started, and a [depends] list
   * are optional.
   */
  GrinderTask(this.name,
      {this.taskFunction, this.depends : const [], this.description});

  /**
   * This method is invoked when the task is started. If a task was created with
   * a [TaskFunction], that function will be invoked by this method.
   */
  dynamic execute(GrinderContext context) {
    return (taskFunction != null) ? taskFunction(context) : null;
  }

  String toString() => "[${name}]";
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
