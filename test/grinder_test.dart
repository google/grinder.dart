// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder_test;

import 'dart:async';
import 'dart:mirrors';

import 'package:grinder/grinder.dart' hide fail;
import 'package:grinder/src/discover_tasks.dart';
import 'package:test/test.dart';

main() {
  group('grinder', () {
    test('tasks must have a task function or dependencies', () {
      expect(() {
        new GrinderTask('foo', taskFunction: null, depends: []);
      }, throwsA(new isInstanceOf<GrinderException>()));
    });

    test('badTaskName', () {
      // test that a bad task name throws
      Grinder grinder = new Grinder();
      grinder.addTask(new GrinderTask('foo', taskFunction: () {}));
      expect(() => grinder.start(['bar'], dontRun: true),
          throwsA(new isInstanceOf<GrinderException>()));
    });

    test('duplicate task name', () {
      Grinder grinder = new Grinder();
      grinder.addTask(new GrinderTask('foo', taskFunction: () {}));
      grinder.addTask(new GrinderTask('foo', taskFunction: () {}));
      expect(() => grinder.start(['foo'], dontRun: true),
          throwsA(new isInstanceOf<GrinderException>()));
    });

    test('badDependencyName', () {
      // test that a bad task name throws
      Grinder grinder = new Grinder();
      grinder.addTask(new GrinderTask('foo', depends: ['baz']));
      expect(() => grinder.start(['foo'], dontRun: true),
          throwsA(new isInstanceOf<GrinderException>()));
    });

    test('default task is run by default', () {
      Grinder grinder = new Grinder();
      grinder.addTask(new GrinderTask('foo', taskFunction: () {}));
      grinder.defaultTask = new GrinderTask('bar', depends: ['foo']);
      grinder.start([], dontRun: true);
      expect(grinder.getBuildOrder(),
          orderedEquals([grinder.getTask('foo'), grinder.getTask('bar')]));
    });

    test('throws when overwriting default task', () {
      Grinder grinder = new Grinder();
      grinder.defaultTask = new GrinderTask('foo', taskFunction: () {});
      expect(() {
        grinder.defaultTask = new GrinderTask('bar');
      }, throwsA(new isInstanceOf<GrinderException>()));
    });

    test('test that dependency cycles are caught', () {
      Grinder grinder = new Grinder();
      grinder.addTask(new GrinderTask('foo', depends: ['bar']));
      grinder.addTask(new GrinderTask('bar', depends: ['foo']));
      expect(() => grinder.start(['foo'], dontRun: true),
          throwsA(new isInstanceOf<GrinderException>()));
    });

    test('stringEscape', () {
      // test that we execute tasks in the correct order
      Grinder grinder = new Grinder();
      grinder.addTask(new GrinderTask('b', taskFunction: () {}));
      grinder.addTask(new GrinderTask('d', taskFunction: () {}));
      grinder.addTask(new GrinderTask('a', depends: ['b']));
      grinder.addTask(new GrinderTask('c', depends: ['d']));
      grinder.addTask(new GrinderTask('e', depends: ['a', 'c']));
      grinder.start(['e'], dontRun: true);
      expect(grinder.getBuildOrder(), orderedEquals([
        grinder.getTask('b'),
        grinder.getTask('a'),
        grinder.getTask('d'),
        grinder.getTask('c'),
        grinder.getTask('e')
      ]));
    });

    test('task execution order 1', () {
      Grinder grinder = new Grinder();
      grinder.addTask(new GrinderTask('setup', taskFunction: () {}));
      grinder.addTask(new GrinderTask('mode-notest', taskFunction: () {}));
      grinder.addTask(new GrinderTask('mode-test', taskFunction: () {}));
      grinder.addTask(new GrinderTask('compile', depends: ['setup']));
      grinder.addTask(
          new GrinderTask('deploy', depends: ['setup', 'mode-notest']));
      grinder.addTask(
          new GrinderTask('deploy-test', depends: ['setup', 'mode-test']));
      grinder.addTask(new GrinderTask('docs', depends: ['setup']));
      grinder.addTask(
          new GrinderTask('archive', depends: ['mode-notest', 'compile']));
      grinder.addTask(
          new GrinderTask('release', depends: ['mode-notest', 'compile']));

      grinder.start(['archive'], dontRun: true);
      expect(grinder.getBuildOrder(), orderedEquals([
        grinder.getTask('mode-notest'),
        grinder.getTask('setup'),
        grinder.getTask('compile'),
        grinder.getTask('archive')
      ]));
    });

    test('task execution order 2', () {
      Grinder grinder = new Grinder();
      grinder.addTask(new GrinderTask('setup', taskFunction: () {}));
      grinder.addTask(new GrinderTask('mode-notest', taskFunction: () {}));
      grinder.addTask(new GrinderTask('mode-test', taskFunction: () {}));
      grinder.addTask(new GrinderTask('compile', depends: ['setup']));
      grinder.addTask(
          new GrinderTask('deploy', depends: ['setup', 'mode-notest']));
      grinder.addTask(
          new GrinderTask('deploy-test', depends: ['setup', 'mode-test']));
      grinder.addTask(new GrinderTask('docs', depends: ['setup']));
      grinder.addTask(
          new GrinderTask('archive', depends: ['mode-notest', 'compile']));
      grinder.addTask(
          new GrinderTask('release', depends: ['mode-notest', 'compile']));

      grinder.start(['docs'], dontRun: true);
      expect(grinder.getBuildOrder(),
          orderedEquals([grinder.getTask('setup'), grinder.getTask('docs')]));
    });

    test('task execution order 3', () {
      Grinder grinder = new Grinder();
      grinder.addTask(new GrinderTask('setup', taskFunction: () {}));
      grinder.addTask(new GrinderTask('mode-notest', taskFunction: () {}));
      grinder.addTask(new GrinderTask('mode-test', taskFunction: () {}));
      grinder.addTask(new GrinderTask('compile', depends: ['setup']));
      grinder.addTask(
          new GrinderTask('deploy', depends: ['setup', 'mode-notest']));
      grinder.addTask(
          new GrinderTask('deploy-test', depends: ['setup', 'mode-test']));
      grinder.addTask(new GrinderTask('docs', depends: ['setup']));
      grinder.addTask(
          new GrinderTask('archive', depends: ['mode-notest', 'compile']));
      grinder.addTask(
          new GrinderTask('release', depends: ['mode-notest', 'compile']));

      grinder.start(['docs', 'archive'], dontRun: true);
      expect(grinder.getBuildOrder(), orderedEquals([
        grinder.getTask('setup'),
        grinder.getTask('docs'),
        grinder.getTask('mode-notest'),
        grinder.getTask('compile'),
        grinder.getTask('archive')
      ]));
    });

    test('task execution order 4', () {
      Grinder grinder = new Grinder();
      grinder.addTask(new GrinderTask('setup', taskFunction: () {}));
      grinder.addTask(new GrinderTask('mode-notest', taskFunction: () {}));
      grinder.addTask(new GrinderTask('mode-test', taskFunction: () {}));
      grinder.addTask(new GrinderTask('compile', depends: ['setup']));
      grinder.addTask(
          new GrinderTask('deploy', depends: ['setup', 'mode-notest']));
      grinder.addTask(
          new GrinderTask('deploy-test', depends: ['setup', 'mode-test']));
      grinder.addTask(new GrinderTask('docs', depends: ['setup']));
      grinder.addTask(
          new GrinderTask('archive', depends: ['mode-notest', 'compile']));
      grinder.addTask(
          new GrinderTask('release', depends: ['mode-notest', 'compile']));

      grinder.addTask(new GrinderTask('clean', taskFunction: () {}));

      grinder.start(['clean'], dontRun: true);
      expect(
          grinder.getBuildOrder(), orderedEquals([grinder.getTask('clean')]));
    });

    test('returns future', () {
      StringBuffer buf = new StringBuffer();
      Grinder grinder = new Grinder();

      grinder.addTask(new GrinderTask('a1', taskFunction: (c) {
        Completer completer = new Completer();
        new Timer(new Duration(milliseconds: 100), () {
          buf.write('a');
          completer.complete();
        });
        return completer.future;
      }));
      grinder.addTask(new GrinderTask('a2', depends: ['a1'], taskFunction: (c) {
        buf.write('b');
      }));

      return grinder.start(['a2']).then((_) {
        expect(buf.toString(), 'ab');
      });
    });

    test('throw on fail', () {
      Grinder grinder = new Grinder();
      grinder.addTask(new GrinderTask('i_throw',
          taskFunction: (GrinderContext context) {
        context.fail('boo');
      }));

      expect(grinder.start(['i_throw']),
          throwsA(new isInstanceOf<GrinderException>()));
    });

    test('handle function references properly', () async {
      int callCount = 0;
      someAsyncTask = () {
        return new Future.delayed(const Duration(milliseconds: 20), () {})
            .then((_) {
          expect(callCount, 0);
          callCount++;
        });
      };
      startTask = () {
        expect(callCount, 1);
        callCount++;
      };

      Grinder grinder = new Grinder();
      discoverTasks(grinder, currentMirrorSystem().findLibrary(#grinder_test));
      await grinder.start(['start']);
    });
  });
}

Function someAsyncTask;

@Task('someAsync')
someAsync() => someAsyncTask();

Function startTask;

@Task('start')
@Depends(someAsync)
start() => startTask();
