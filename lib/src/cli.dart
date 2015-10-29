// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.cli;

import 'dart:async';
import 'dart:convert' show JSON, UTF8;

import 'package:unscripted/unscripted.dart';

import '../grinder.dart';
import 'cli_util.dart';
import 'singleton.dart' as singleton;
import 'utils.dart';

// This version must be updated in tandem with the pubspec version.
const String appVersion = '0.8.0';

List<String> grinderArgs() => _args;
List<String> _args;
bool _verifyProjectRoot;

Future handleArgs(List<String> args, {bool verifyProjectRoot: false}) {
  _args = args == null ? [] : args;
  _verifyProjectRoot = verifyProjectRoot;
  return script.execute(grinderArgs());
}

// TODO: Re-inline this variable once the fix for http://dartbug.com/23354
//       is released.
const _completion = const Completion();
@Command(
    allowTrailingOptions: true,
    help: 'Dart workflows, automated.',
    plugins: const [_completion])
cli(@Rest(
        valueHelp: 'tasks',
        help: _getTaskHelp,
        allowed: _allowedTasks,
        parser: parseTaskInvocation)
    List<TaskInvocation> partialInvocations,
    {@Flag(help: 'Print the version of grinder.') bool version: false,
    @Option(help: 'Set the location of the Dart SDK.') String dartSdk,
    @Group(_getTaskOptions, hide: true) Map<String, dynamic> taskOptions}) {
  if (version) {
    const pubUrl = 'https://pub.dartlang.org/packages/grinder.json';

    print('grinder version ${appVersion}');

    return httpGet(pubUrl).then((String str) {
      List versions = JSON.decode(str)['versions'];
      if (appVersion != versions.last) {
        print("Version ${versions.last} is available! Run `pub global activate"
            " grinder` to get the latest version.");
      } else {
        print('grinder is up to date!');
      }
    }).catchError((e) => null);
  } else if (partialInvocations.isEmpty && !singleton.grinder.hasDefaultTask) {
    // Support this directly in `unscripted`.
    print('No default task defined.');
    return script.execute(['-h']);
  } else {
    if (_verifyProjectRoot) {
      // Verify that we're running from the project root.
      if (!getFile('pubspec.yaml').existsSync()) {
        fail('This script must be run from the project root.');
      }
    }

    for (TaskInvocation invocation in partialInvocations) {
      var task = singleton.grinder.getTask(invocation.name);
      if (task == null) fail("Error, no task found: '${invocation.name}'.");
    }

    var invocations = partialInvocations.map((TaskInvocation partial) {
      var task = singleton.grinder.getTask(partial.name);
      var raw = addTaskOptionsToInvocation(task, partial, taskOptions);
      return applyTaskToInvocation(task, raw);
    });

    Future result = singleton.grinder.start(invocations);

    return result.catchError((e, st) {
      // TODO: The stacktrace is being whittled away when it's a future.
      String message;
      if (st != null) {
        message = '\n${e}\n${cleanupStackTrace(st)}';
      } else {
        message = '\n${e}';
      }
      fail(message);
    });
  }

  return new Future.value();
}

Script script = new Script(cli);

Iterable<Option> _getTaskOptions() => getTaskOptions(singleton.grinder);

String _getTaskHelp() => getTaskHelp(singleton.grinder);

List<String> _allowedTasks() => allowedTasks(singleton.grinder);
