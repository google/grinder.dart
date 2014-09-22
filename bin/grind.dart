// Copyright 2014 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/**
 * Look for `tool/grind.dart` relative to the current directory and run it.
 */
library grinder.grind;

import 'grinder.dart' as g;

void main(List args) => g.runScript('tool/grind.dart', args);
