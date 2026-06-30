// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/// Dart workflows, automated.
///
/// See the [README][] for detailed usage information.
///
/// [README]: https://pub.dartlang.org/packages/grinder
library;

import 'dart:mirrors';

import 'src/cli.dart';
import 'src/discover_tasks.dart';
import 'src/grinder_context.dart';
import 'src/grinder_exception.dart';
import 'src/singleton.dart';

export 'src/annotations.dart';
export 'src/cli.dart' show grinderArgs;
export 'src/files.dart';
export 'src/grinder.dart';
export 'src/grinder_context.dart';
export 'src/grinder_exception.dart';
export 'src/grinder_task.dart';
export 'src/run.dart';
export 'src/sdk.dart';
export 'src/task_invocation.dart';
export 'src/tools.dart';

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
Future<void> grind(List<String> args, {bool verifyProjectRoot = true}) {
  try {
    discoverTasks(grinder, currentMirrorSystem().isolate.rootLibrary);
    return runTasks(args, verifyProjectRoot: verifyProjectRoot);
  } catch (e) {
    if (e is GrinderException) {
      fail(e.message);
    }

    return Future.error(e);
  }
}
