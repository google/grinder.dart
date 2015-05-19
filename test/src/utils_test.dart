// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.utils_test;

import 'package:grinder/src/utils.dart';
import 'package:test/test.dart';

main() {
  group('src.utils', () {
    test('httpGet', () {
      return httpGet('http://httpbin.org/get').then((result) {
        expect(result, isNotEmpty);
      });
    });

    test('ResettableTimer', () {
      ResettableTimer timer = new ResettableTimer(new Duration(seconds: 1), () {
        fail("timer shouldn't have fired'");
      });
      expect(timer.isActive, true);
      timer.reset();
      expect(timer.isActive, true);
      timer.cancel();
      expect(timer.isActive, false);
    });
  });
}
