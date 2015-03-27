// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.singleton;

import '../grinder.dart';
import 'utils.dart';

final Grinder grinder = new Grinder();

final ZonedValue zonedContext = new ZonedValue(new _NoopContext());

// TODO: Move to having the default context fast-fail.

class _NoopContext implements GrinderContext {
  Grinder get grinder => null;

  GrinderTask get task => null;

  void fail(String message) {
    throw new GrinderException(message);
  }

  void log(String message) => print(message);
}
