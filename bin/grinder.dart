// Copyright 2014 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/// Look for `tool/grind.dart` relative to the current directory and run it.
library grinder.bin.grinder;

import 'dart:io';

void main(List args) => runScript('tool/grind.dart', args);

void runScript(String script, List args) {
  File file = new File(script);

  if (!file.existsSync()) {
    stderr.writeln(
        "Error: expected to find '${script}' relative to the current directory.");
    exit(1);
  }

  List newArgs = [script]..addAll(args);
  _runProcessAsync(Platform.isWindows ? 'dart.exe' : 'dart', newArgs);
}

void _runProcessAsync(String executable, List<String> arguments) {
  Process.start(executable, arguments).then((Process process) {
    stdout.addStream(process.stdout);
    stderr.addStream(process.stderr);
    return process.exitCode.then((int code) => exit(code));
  });
}
