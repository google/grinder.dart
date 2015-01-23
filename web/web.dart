// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.web_test;

import 'dart:async';

import 'package:grinder/src/webtest.dart';
import 'package:unittest/unittest.dart';

void main() {
  // Set up the test environment.
  WebTestConfiguration.setupTestEnvironment();

  // Define the tests.
  defineTests();
}

defineTests() {
  group('fruit', () {
    test('apples', () {
      expect(1, 1);
    });
    test('oranges', () {
      expect(1, 1);
    });
    test('short', () {
      return new Future.delayed(new Duration(seconds: 1), () {
        expect(1, 1);
      });
    });
//    test('long', () {
//      return new Future.delayed(new Duration(seconds: 45), () {
//        expect(1, 1);
//      });
//    });
  });
}
