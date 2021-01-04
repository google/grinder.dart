// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.cli_util;

import 'package:cli_util/cli_logging.dart' show Ansi;

import '../grinder.dart';

String getTaskHelp(Grinder grinder, {bool useColor = true}) {
  if (grinder.tasks.isEmpty) {
    return '  No tasks defined.';
  }

  // Calculate the dependencies.
  grinder.start([], dontRun: true);

  final tasks = grinder.tasks.toList();

  final ansi = Ansi(useColor);

  return tasks
      .map((GrinderTask task) {
        final deps = grinder.getImmediateDependencies(task);

        final buffer = StringBuffer();
        var label = ansi.emphasized(task.name);
        final diff = label.length - task.name.length;
        if (grinder.defaultTask == task) {
          label += ' (default)';
        }
        buffer.write('  ${label.padRight(20 + diff)} ');
        final depTasks = deps.map((d) {
          return '${ansi.green}${d.name}${ansi.none}';
        }).join(' ');
        final depText = '(depends on: $depTasks)';
        if (task.description?.isNotEmpty ?? false) {
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
