// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.singleton;

import '../grinder.dart';
import 'utils.dart';

final Grinder grinder = new Grinder();

final ZonedValue zonedContext = new ZonedValue(new _NoopContext());

class _NoopContext implements GrinderContext {
  Grinder get grinder => null;

  GrinderTask get task => null;

  // TODO: implement fail
  void fail(String message) { }

  // TODO: implement log
  void log(String message) { }
}
