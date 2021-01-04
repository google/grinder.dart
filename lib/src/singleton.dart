// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.singleton;

import 'dart:io';

import '../grinder.dart';
import 'utils.dart';

final Grinder grinder = Grinder();

final ZonedValue zonedContext = ZonedValue(_NoopContext());

class _NoopContext implements GrinderContext {
  @override
  Grinder get grinder => throw StateError('Grinder is not initialized.');

  @override
  GrinderTask get task => throw StateError('Grinder is not initialized.');

  @override
  TaskInvocation get invocation =>
      throw StateError('Grinder is not initialized.');

  @override
  Never fail(String message) {
    stderr.writeln(message);
    exit(1);
  }

  @override
  void log(String message) => print(message);
}
