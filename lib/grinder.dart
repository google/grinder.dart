// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/**
 * Dart workflows, automated.
 *
 * See the [README][] for detailed usage information.
 *
 * [README]: https://pub.dartlang.org/packages/grinder
 */
library grinder;

import 'dart:async';
import 'dart:mirrors';

import 'src/cli.dart';
import 'src/discover_tasks.dart';
import 'src/grinder_context.dart';
import 'src/grinder_exception.dart';
import 'src/grinder_task.dart';
import 'src/singleton.dart';
import 'src/task_invocation.dart';

export 'grinder_files.dart';
export 'grinder_sdk.dart';
export 'grinder_tools.dart';
export 'src/annotations.dart';
export 'src/cli.dart' show grinderArgs;
export 'src/grinder.dart';
export 'src/grinder_context.dart';
export 'src/grinder_exception.dart';
export 'src/grinder_task.dart';
export 'src/task_invocation.dart';

/// Run the grinder file.
///
/// First, discovers the tasks declared in your grinder file. Then, handles the
/// command-line [args] either by running tasks or responding to recognized
/// options such as --help.
///
/// If [verifyProjectRoot] is true, grinder will verify that the script is being
/// run from a project root.
///
/// If a task fails, it throws and runs no further tasks.
Future grind(List<String> args, {bool verifyProjectRoot: true}) {
  try {
    discoverTasks(grinder, currentMirrorSystem().isolate.rootLibrary);
    return handleArgs(args, verifyProjectRoot: verifyProjectRoot);
  } catch (e) {
    if (e is GrinderException) {
      fail(e.message);
    } else {
      return new Future.error(e);
    }
  }
}

/**
 * Start the build process. This should be called at the end of the `main()`
 * method. If there is a task failure, this method will halt task execution and
 * throw.
 */
@Deprecated('Use `grind` instead.')
Future startGrinder(List<String> args, {bool verifyProjectRoot: true}) {
  return handleArgs(args, verifyProjectRoot: verifyProjectRoot);
}

/// Used to define a method body for a task. Note: a task's context is now
/// available as a global variable ('context'). Your task functions should no
/// longer be definied with a single `GrinderContext` parameter.
@Deprecated('''Use a nullary function instead.  A task's context can now be
accessed via the top-level `context` getter.''')
typedef dynamic TaskFunction(GrinderContext context);

/**
 * Add a new task definition to the global [Grinder] instance. A [name] is
 * required. If specified, a [taskFunction] is invoked when the task starts.
 * Any dependencies of the task, that need to run before it, should be passed
 * in via [depends].
 */
@Deprecated('Use the task annotations instead.')
void task(String name,
          [Function taskFunction, List<String> depends = const []]) {
  grinder.addTask(new GrinderTask(
      name,
      taskFunction: taskFunction,
      depends: depends.map((dep) => new TaskInvocation(dep))));
}
