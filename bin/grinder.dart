// Copyright 2014 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/**
 * Look for `tool/grind.dart` relative to the current directory and run it.
 */
library grinder.grinder;

import 'grind.dart' as grind;

@deprecated
void main(List args) {
  print("The 'grinder' entrypoint is deprecated; please use the 'grind'.");
  print('');

  grind.main(args);
}
