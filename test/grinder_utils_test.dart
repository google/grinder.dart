// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder_utils_test;

import 'package:grinder/grinder.dart';
import 'package:unittest/unittest.dart';

main() {
  group('grinder.utils', () {
    test('get sdkDir', () {
      expect(sdkDir, isNotNull);
    });
  });
}
