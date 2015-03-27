// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.tools_test;

import 'dart:io';

import 'package:grinder/grinder.dart';
import 'package:unittest/unittest.dart';

import 'test_utils.dart';

main() {
  group('grinder.tools', () {
    test('sdkDir', () {
      if (Platform.environment['DART_SDK'] != null) {
        expect(sdkDir, isNotNull);
      }
    });

    test('getSdkDir', () {
      expect(getSdkDir(), isNotNull);
      expect(getSdkDir(grinderArgs()), isNotNull);
      expect(getSdkDir([]), isNotNull);
    });

    test('get dartVM', () {
      expect(dartVM, isNotNull);
    });

    test('dart2js version', () {
      MockGrinderContext context = new MockGrinderContext();
      Dart2js.version();
      expect(context.isFailed, false);
    });

    test('analyzer version', () {
      MockGrinderContext context = new MockGrinderContext();
      Analyzer.version();
      expect(context.isFailed, false);
    });
  });

  group('grinder.tools.pub', () {
    test('version', () {
      MockGrinderContext context = new MockGrinderContext();
      Pub.version();
      expect(context.isFailed, false);
    });

    test('global list', () {
      MockGrinderContext context = new MockGrinderContext();
      expect(Pub.global.list(), isNotNull);
      expect(context.isFailed, false);
    });

    test('isInstalled', () {
      MockGrinderContext context = new MockGrinderContext();
      Pub.global.isInstalled('foo');
      expect(context.isFailed, false);
    });
  });
}
