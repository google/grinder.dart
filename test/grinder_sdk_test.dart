// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.sdk_test;

import 'dart:io' hide ProcessException;

import 'package:grinder/grinder.dart';
import 'package:test/test.dart';

import 'src/_common.dart';

main() {
  group('grinder.sdk', () {
    test('sdkDir', () {
      if (Platform.environment['DART_SDK'] != null) {
        expect(sdkDir, isNotNull);
      }
    });

    test('sdkDir', () {
      expect(sdkDir, isNotNull);
    });

    test('get dartVM', () {
      expect(dartVM, isNotNull);
    });

    test('Dart.version', () {
      expect(Dart.version(quiet: true), isNotEmpty);
    });

    grinderTest('dart2js version', () {
      expect(Dart2js.version(), isNotNull);
    }, (MockGrinderContext ctx) {
      expect(ctx.logBuffer, isNotEmpty);
      expect(ctx.isFailed, false);
    });

    grinderTest('analyzer version', () {
      expect(Analyzer.version(), isNotNull);
    }, (MockGrinderContext ctx) {
      expect(ctx.logBuffer, isNotEmpty);
      expect(ctx.isFailed, false);
    });

    grinderTest('Pub.version', () {
      expect(Pub.version(), isNotNull);
    }, (ctx) {
      expect(ctx.logBuffer, isNotEmpty);
      expect(ctx.isFailed, false);
    });

    grinderTest('Pub.list', () {
      expect(Pub.global.list(), isNotNull);
    }, (ctx) {
      expect(ctx.logBuffer, isEmpty);
      expect(ctx.isFailed, false);
    });

    grinderTest('Pub.isActivated', () {
      expect(Pub.global.isActivated('foo'), false);
    }, (ctx) {
      expect(ctx.isFailed, false);
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

  group('grinder.sdk Dart', () {
    FilePath temp;
    File file;

    setUp(() {
      temp = FilePath.createSystemTemp();
      file = temp.join('runAsync.dart').asFile;
      // TODO: should this be checked in somewhere?
      file.writeAsStringSync('void main() {print("hello from runAsync");}');
    });

    test('runAsync', () async {
      String result = await Dart.runAsync(file.path);
      expect(result, startsWith("hello from runAsync"));
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

  group('grinder.sdk Analyzer', () {
    test(
        'should throw on non-existing file',
        () => expect(() => Analyzer.analyze('xyz'),
            throwsA(new isInstanceOf<ProcessException>())));

    test(
        'should analyze a list of files ',
        () => expect(
            () => Analyzer
                .analyze(['test/grinder_sdk_test.dart', 'tool/grind.dart']),
            isNot(throwsA(new isInstanceOf<ProcessException>()))));
  });
}
