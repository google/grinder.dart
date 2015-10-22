// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.utils_test;

import 'dart:io';

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

    test('coerceToPathList', () {
      expect(coerceToPathList([]), isEmpty);
      expect(coerceToPathList('foo'), ['foo']);
      expect(coerceToPathList(new File('foo')), ['foo']);
      expect(coerceToPathList(new Directory('foo')), ['foo']);
      expect(coerceToPathList(['a', 'b']), ['a', 'b']);
      expect(coerceToPathList([new File('a'), new File('b')]), ['a', 'b']);
      expect(coerceToPathList([new Directory('a'), new Directory('b')]),
          ['a', 'b']);
      expect(coerceToPathList([new Directory('a'), new File('b'), 'c']),
          ['a', 'b', 'c']);
    });

    test('findDartSourceFiles', () {
      var testFiles = findDartSourceFiles(['test']);
      expect(testFiles.length, greaterThan(0));
      expect(
          testFiles,
          anyElement((f) => new File(f).existsSync() &&
              FileSystemEntity.typeSync(f) == FileSystemEntityType.FILE));
    });
  });
}
