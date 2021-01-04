// Copyright 2014 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.test.common;

import 'dart:async';

import 'package:grinder/grinder.dart';
import 'package:grinder/src/singleton.dart';
import 'package:test/test.dart';

typedef TestVerification = Function(MockGrinderContext ctx);

TaskFunction nullTaskFunction = ([TaskArgs? args]) => null;

void grinderTest(String name, Function setup, TestVerification verify) {
  test(name, () {
    final ctx = MockGrinderContext();
    return ctx.runZoned(() => setup()).then((_) => verify(ctx));
  });
}

class MockGrinderContext implements GrinderContext {
  @override
  Grinder get grinder =>
      throw UnsupportedError('MockGrinderContext.grinder is unsupported');
  @override
  GrinderTask get task =>
      throw UnsupportedError('MockGrinderContext.task is unsupported');
  @override
  TaskInvocation get invocation =>
      throw UnsupportedError('MockGrinderContext.invocation is unsupported');

  StringBuffer logBuffer = StringBuffer();
  StringBuffer failBuffer = StringBuffer();

  bool get isFailed => failBuffer.isNotEmpty;

  @override
  void log(String message) => logBuffer.write('${message}\n');

  @override
  Never fail(String message) {
    failBuffer.write('${message}\n');
    throw GrinderException(message);
  }

  Future runZoned(void Function() f) {
    var result = zonedContext.withValue(this, f);
    return result is Future ? result : Future.value();
  }
}
