// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.sdk_test;

import 'dart:io';

import 'package:grinder/grinder.dart';
import 'package:unittest/unittest.dart';

import 'src/_common.dart';

main() {
  group('grinder.sdk', () {
    MockGrinderContext mockContext;

    setUp(() {
      mockContext = new MockGrinderContext();
    });

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

    test('Dart.location', () {
      expect(Dart.location, isNotNull);
    });

    test('Dart.version', () {
      expect(Dart.version(quiet: true), isNotEmpty);
    });

    test('dart2js version', () {
      return mockContext.runZoned(() {
        expect(Dart2js.version(), isNotNull);
      }).then((_) {
        expect(mockContext.logBuffer, isNotEmpty);
        expect(mockContext.isFailed, false);
      });
    });

    test('analyzer version', () {
      return mockContext.runZoned(() {
        expect(Analyzer.version(), isNotNull);
      }).then((_) {
        expect(mockContext.logBuffer, isNotEmpty);
        expect(mockContext.isFailed, false);
      });
    });

    test('Pub.version', () {
      return mockContext.runZoned(() {
        expect(Pub.version(), isNotNull);
      }).then((_) {
        expect(mockContext.logBuffer, isNotEmpty);
        expect(mockContext.isFailed, false);
      });
    });

    // See #166.
//    test('Pub.list', () {
//      return mockContext.runZoned(() {
//        expect(Pub.global._list(), isNotNull);
//      }).then((_) {
//        expect(mockContext.logBuffer, isNotEmpty);
//        expect(mockContext.isFailed, false);
//      });
//    });

    test('Pub.isActivated', () {
      return mockContext.runZoned(() {
        expect(Pub.global.isActivated('foo'), false);
      }).then((_) {
        expect(mockContext.isFailed, false);
      });
    });

    test('PubApp.global', () {
      PubApp grinder = new PubApp.global('grinder');
      expect(grinder.isGlobal, true);
      if (!grinder.isActivated) {
        grinder.activate();
        expect(grinder.isActivated, true);
      }
    });

    test('PubApp.local', () {
      PubApp grinder = new PubApp.local('grinder');
      expect(grinder.isGlobal, false);
    });
  });

  group('grinder.sdk DartFmt', () {
    FilePath temp;
    File file;

    setUp(() {
      temp = FilePath.createSystemTemp();
      file = temp.join('foo.dart').asFile;
      file.writeAsStringSync('void main() {}');
    });

    tearDown(() {
      temp.delete();
    });

    test('dryRun', () {
      bool wouldChange = DartFmt.dryRun(file);
      expect(wouldChange, true);
    });

    test('format', () {
      String originalText = file.readAsStringSync();
      DartFmt.format(file);
      String newText = file.readAsStringSync();
      expect(newText, isNot(equals(originalText)));
    });
  });
}
