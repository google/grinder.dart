// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.tools_test;

import 'package:grinder/grinder.dart';
import 'package:test/test.dart';

main() {
  group('grinder.tools', () {
    test('Chrome.getBestInstalledChrome', () {
      Chrome chrome = Chrome.getBestInstalledChrome();
      // Expect that we can always locate a Chrome, even on the bots.
      expect(chrome.exists, true);
    });

    test('Dartium', () {
      /*Chrome dartium =*/ new Dartium();
      // This may not always be true; assert that we can create Dartium.
      //expect(dartium.exists, true);
    });
  });
}
