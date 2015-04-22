// Copyright 2014 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.test.common;

import 'dart:async';

import 'package:grinder/grinder.dart';
import 'package:grinder/src/singleton.dart';

class MockGrinderContext implements GrinderContext {
  Grinder grinder;
  GrinderTask task;

  StringBuffer logBuffer = new StringBuffer();
  StringBuffer failBuffer = new StringBuffer();

  bool get isFailed => failBuffer.isNotEmpty;

  void log(String message) => logBuffer.write('${message}\n');
  void fail(String message) => failBuffer.write('${message}\n');

  Future runZoned(Function f) {
    var result = zonedContext.withValue(this, f);
    return result is Future ? result : new Future.value();
  }
}
