// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder_test;

import 'package:grinder/grinder.dart';
import 'package:unittest/unittest.dart';

main() {
  group('grinder', () {
    test('badTaskName', () {
      // test that a bad task name throws
      Grinder grinder = new Grinder();
      grinder.addTask(new GrinderTask('foo'));
      expect(() => grinder.start(['bar'], dontRun: true), throwsA(new isInstanceOf<GrinderException>()));
    });

    test('badDependencyName', () {
      // test that a bad task name throws
      Grinder grinder = new Grinder();
      grinder.addTask(new GrinderTask('foo', depends: ['baz']));
      expect(() => grinder.start(['foo'], dontRun: true), throwsA(new isInstanceOf<GrinderException>()));
    });

    test('htmlEscape', () {
      // test that dependency cycles are caught
      Grinder grinder = new Grinder();
      grinder.addTask(new GrinderTask('foo', depends: ['bar']));
      grinder.addTask(new GrinderTask('bar', depends: ['foo']));
      expect(() => grinder.start(['foo'], dontRun: true), throwsA(new isInstanceOf<GrinderException>()));
    });

    test('stringEscape', () {
      // test that we execute tasks in the correct order
      Grinder grinder = new Grinder();
      grinder.addTask(new GrinderTask('b'));
      grinder.addTask(new GrinderTask('d'));
      grinder.addTask(new GrinderTask('a', depends: ['b']));
      grinder.addTask(new GrinderTask('c', depends: ['d']));
      grinder.addTask(new GrinderTask('e', depends: ['a', 'c']));
      grinder.start(['e'], dontRun: true);
      expect(grinder.getBuildOrder(), orderedEquals([
          grinder.getTask('b'), grinder.getTask('a'), grinder.getTask('d'), grinder.getTask('c'), grinder.getTask('e')
      ]));
    });
  });
}
