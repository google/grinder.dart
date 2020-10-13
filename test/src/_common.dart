// Copyright 2014 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.test.common;

import 'dart:async';

import 'package:grinder/grinder.dart';
import 'package:grinder/src/singleton.dart';
import 'package:test/test.dart';

typedef TestVerification = Function(MockGrinderContext ctx);

TaskFunction nullTaskFunction = ([TaskArgs args]) => null;

void grinderTest(String name, Function setup, TestVerification verify) {
  test(name, () {
    final ctx = MockGrinderContext();
    return ctx.runZoned(() => setup()).then((_) => verify(ctx));
  });
}

class MockGrinderContext implements GrinderContext {
  @override
  Grinder grinder;
  @override
  GrinderTask task;
  @override
  TaskInvocation invocation;

  StringBuffer logBuffer = StringBuffer();
  StringBuffer failBuffer = StringBuffer();

  bool get isFailed => failBuffer.isNotEmpty;

  @override
  void log(String message) => logBuffer.write('${message}\n');

  @override
  Null fail(String message) {
    failBuffer.write('${message}\n');
    throw GrinderException(message);
  }

  Future runZoned(Function f) {
    var result = zonedContext.withValue(this, f);
    return result is Future ? result : Future.value();
  }
}
