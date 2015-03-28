// Copyright 2014 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder_test_utils;

import 'package:grinder/grinder.dart';

class MockGrinderContext implements GrinderContext {
  Grinder grinder;
  GrinderTask task;

  StringBuffer logBuffer = new StringBuffer();
  StringBuffer failBuffer = new StringBuffer();

  bool get isFailed => failBuffer.isNotEmpty;

  void log(String message) => logBuffer.write(message);
  void fail(String message) => failBuffer.write(message);
}
