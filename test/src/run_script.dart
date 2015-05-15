// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show JSON;
import 'dart:io' as io;

/// Helper for tests in `run_test.dart`.
/// Return information about how the script was launched to be investigated by
/// the caller.
void main(List<String> args) {
  Map json = {
    'arguments': args,
    'workingDirectory': io.Directory.current.path,
    'environment': io.Platform.environment,
    'x1': io.Platform.executable,
    'x2': io.Platform.executableArguments,
  };
  print(JSON.encode(json));
  var exitCode = io.Platform.environment['USE_EXIT_CODE'];
  if(exitCode != null && exitCode.isNotEmpty) {
    io.exit(int.parse(exitCode));
  }
}
