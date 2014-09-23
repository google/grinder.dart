// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder_utils_test;

import 'dart:io';

import 'package:grinder/grinder.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

main() {
  group('grinder.utils', () {
    test('get sdkDir', () {
      if (Platform.environment['DART_SDK'] != null) {
        expect(sdkDir, isNotNull);
      }
    });

    test('pub version', () {
      MockGrinderContext context = new MockGrinderContext();
      Pub.version(context);
      expect(context.isFailed, false);
    });

    test('dart2js version', () {
      MockGrinderContext context = new MockGrinderContext();
      Dart2js.version(context);
      expect(context.isFailed, false);
    });

    test('analyzer version', () {
      MockGrinderContext context = new MockGrinderContext();
      Analyzer.version(context);
      expect(context.isFailed, false);
    });
  });
}
