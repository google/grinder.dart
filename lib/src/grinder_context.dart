// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.grinder_context;

import 'grinder.dart';
import 'grinder_exception.dart';
import 'grinder_task.dart';
import 'singleton.dart';
import 'task_invocation.dart';

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

  /// The current [TaskInvocation].
  final TaskInvocation invocation;

  GrinderContext(this.grinder, this.task, this.invocation);

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
    log('failed: ${message}');
    throw new GrinderException(message);
  }

  String toString() => "Context for ${task}";
}

// Zone variables.

/// Get the [GrinderContext] for the currently executing task.
GrinderContext get context => zonedContext.value;

/// Log an informational message to Grinder's output.
void log(String message) => context.log(message);

/// Halt task execution; throws an exception with the given error message.
void fail(String message) => context.fail(message);
