// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.cli_util;

import 'package:cli_util/cli_logging.dart' show Ansi;

import '../grinder.dart';

// TODO: pass args to tasks

String getTaskHelp(Grinder grinder, {bool useColor: true}) {
  if (grinder.tasks.isEmpty) {
    return '  No tasks defined.';
  }

  // Calculate the dependencies.
  grinder.start([], dontRun: true);

  List<GrinderTask> tasks = grinder.tasks.toList();

  final Ansi ansi = new Ansi(useColor);

  return tasks
      .map((GrinderTask task) {
        Iterable<TaskInvocation> deps = grinder.getImmediateDependencies(task);

        StringBuffer buffer = new StringBuffer();
        String label = ansi.emphasized(task.name);
        int diff = label.length - task.name.length;
        if (grinder.defaultTask == task) {
          label += ' (default)';
        }
        buffer.write('  ${label.padRight(20 + diff)} ');
        String depTasks = deps.map((d) {
          return '${ansi.green}${d.name}${ansi.none}';
        }).join(' ');
        String depText = '(depends on: $depTasks)';
        if (task.description != null) {
          buffer.writeln(task.description);
          if (deps.isNotEmpty) {
            buffer.writeln('  ${''.padRight(20)} $depText');
          }
        } else {
          if (deps.isNotEmpty) buffer.write(depText);
          buffer.writeln();
        }

        return buffer.toString();
      })
      .join()
      .trimRight();
}
