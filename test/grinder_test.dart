// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder_test;

import 'dart:async';

import 'package:grinder/grinder.dart' hide fail;
import 'package:test/test.dart';

import 'src/_common.dart';

void main() {
  group('grinder', () {
    test('tasks must have a task function or dependencies', () {
      expect(() {
        GrinderTask('foo', taskFunction: null, depends: []);
      }, throwsA(isA<GrinderException>()));
    });

    test('badTaskName', () {
      // test that a bad task name throws
      final grinder = Grinder();
      grinder.addTask(GrinderTask('foo', taskFunction: nullTaskFunction));
      expect(() => grinder.start(['bar'], dontRun: true),
          throwsA(isA<GrinderException>()));
    });

    test('duplicate task name', () {
      final grinder = Grinder();
      grinder.addTask(GrinderTask('foo', taskFunction: nullTaskFunction));
      grinder.addTask(GrinderTask('foo', taskFunction: nullTaskFunction));
      expect(() => grinder.start(['foo'], dontRun: true),
          throwsA(isA<GrinderException>()));
    });

    test('badDependencyName', () {
      // test that a bad task name throws
      final grinder = Grinder();
      grinder.addTask(GrinderTask('foo', depends: ['baz']));
      expect(() => grinder.start(['foo'], dontRun: true),
          throwsA(isA<GrinderException>()));
    });

    test('default task is run by default', () {
      final grinder = Grinder();
      grinder.addTask(GrinderTask('foo', taskFunction: ([foo]) => null));
      grinder.defaultTask = GrinderTask('bar', depends: ['foo']);
      grinder.start([], dontRun: true);
      expect(grinder.getBuildOrder(),
          orderedEquals([TaskInvocation('foo'), TaskInvocation('bar')]));
    });

    test('throws when overwriting default task', () {
      final grinder = Grinder();
      grinder.defaultTask = GrinderTask('foo', taskFunction: nullTaskFunction);
      expect(() {
        grinder.defaultTask =
            GrinderTask('bar', taskFunction: nullTaskFunction);
      }, throwsA(isA<GrinderException>()));
    });

    test('test that dependency cycles are caught', () {
      final grinder = Grinder();
      grinder.addTask(GrinderTask('foo', depends: ['bar']));
      grinder.addTask(GrinderTask('bar', depends: ['foo']));
      expect(() => grinder.start(['foo'], dontRun: true),
          throwsA(isA<GrinderException>()));
    });

    test('can invoke a task with arguments', () {
      final grinder = Grinder();
      var received;
      grinder.addTask(GrinderTask('foo', taskFunction: ([TaskArgs args]) {
        received = context.invocation;
      }));
      var sent = TaskInvocation('foo', TaskArgs('foo', ['--foo', '--bar=baz']));
      return grinder.start([sent]).then((_) {
        expect(received, sent);
      });
    });

    test('can invoke a dependency task with arguments', () {
      final grinder = Grinder();
      var invocation;
      grinder.addTask(GrinderTask('foo', taskFunction: ([args]) {
        invocation = context.invocation;
      }));
      var dep = TaskInvocation('foo');
      grinder.addTask(GrinderTask('bar', depends: [dep]));
      return grinder.start(['bar']).then((_) {
        expect(invocation, dep);
      });
    });

    test('stringEscape', () {
      // test that we execute tasks in the correct order
      final grinder = Grinder();
      grinder.addTask(GrinderTask('b', taskFunction: nullTaskFunction));
      grinder.addTask(GrinderTask('d', taskFunction: nullTaskFunction));
      grinder.addTask(GrinderTask('a', depends: ['b']));
      grinder.addTask(GrinderTask('c', depends: ['d']));
      grinder.addTask(GrinderTask('e', depends: ['a', 'c']));
      grinder.start(['e'], dontRun: true);
      expect(
          grinder.getBuildOrder(),
          orderedEquals(['b', 'a', 'd', 'c', 'e']
              .map((taskName) => TaskInvocation(taskName))));
    });

    test('task execution order 1', () {
      final grinder = Grinder();
      grinder.addTask(GrinderTask('setup', taskFunction: nullTaskFunction));
      grinder
          .addTask(GrinderTask('mode-notest', taskFunction: nullTaskFunction));
      grinder.addTask(GrinderTask('mode-test', taskFunction: nullTaskFunction));
      grinder.addTask(GrinderTask('compile', depends: ['setup']));
      grinder.addTask(GrinderTask('deploy', depends: ['setup', 'mode-notest']));
      grinder
          .addTask(GrinderTask('deploy-test', depends: ['setup', 'mode-test']));
      grinder.addTask(GrinderTask('docs', depends: ['setup']));
      grinder
          .addTask(GrinderTask('archive', depends: ['mode-notest', 'compile']));
      grinder
          .addTask(GrinderTask('release', depends: ['mode-notest', 'compile']));

      grinder.start(['archive'], dontRun: true);
      expect(
          grinder.getBuildOrder(),
          orderedEquals(['mode-notest', 'setup', 'compile', 'archive']
              .map((taskName) => TaskInvocation(taskName))));
    });

    test('task execution order 2', () {
      final grinder = Grinder();
      grinder.addTask(GrinderTask('setup', taskFunction: nullTaskFunction));
      grinder
          .addTask(GrinderTask('mode-notest', taskFunction: nullTaskFunction));
      grinder.addTask(GrinderTask('mode-test', taskFunction: nullTaskFunction));
      grinder.addTask(GrinderTask('compile', depends: ['setup']));
      grinder.addTask(GrinderTask('deploy', depends: ['setup', 'mode-notest']));
      grinder
          .addTask(GrinderTask('deploy-test', depends: ['setup', 'mode-test']));
      grinder.addTask(GrinderTask('docs', depends: ['setup']));
      grinder
          .addTask(GrinderTask('archive', depends: ['mode-notest', 'compile']));
      grinder
          .addTask(GrinderTask('release', depends: ['mode-notest', 'compile']));

      grinder.start(['docs'], dontRun: true);
      expect(
          grinder.getBuildOrder(),
          orderedEquals(
              ['setup', 'docs'].map((taskName) => TaskInvocation(taskName))));
    });

    test('task execution order 3', () {
      final grinder = Grinder();
      grinder.addTask(GrinderTask('setup', taskFunction: nullTaskFunction));
      grinder
          .addTask(GrinderTask('mode-notest', taskFunction: nullTaskFunction));
      grinder.addTask(GrinderTask('mode-test', taskFunction: nullTaskFunction));
      grinder.addTask(GrinderTask('compile', depends: ['setup']));
      grinder.addTask(GrinderTask('deploy', depends: ['setup', 'mode-notest']));
      grinder
          .addTask(GrinderTask('deploy-test', depends: ['setup', 'mode-test']));
      grinder.addTask(GrinderTask('docs', depends: ['setup']));
      grinder
          .addTask(GrinderTask('archive', depends: ['mode-notest', 'compile']));
      grinder
          .addTask(GrinderTask('release', depends: ['mode-notest', 'compile']));

      grinder.start(['docs', 'archive'], dontRun: true);
      expect(
          grinder.getBuildOrder(),
          orderedEquals(['setup', 'docs', 'mode-notest', 'compile', 'archive']
              .map((taskName) => TaskInvocation(taskName))));
    });

    test('task execution order 4', () {
      final grinder = Grinder();
      grinder.addTask(GrinderTask('setup', taskFunction: nullTaskFunction));
      grinder
          .addTask(GrinderTask('mode-notest', taskFunction: nullTaskFunction));
      grinder.addTask(GrinderTask('mode-test', taskFunction: nullTaskFunction));
      grinder.addTask(GrinderTask('compile', depends: ['setup']));
      grinder.addTask(GrinderTask('deploy', depends: ['setup', 'mode-notest']));
      grinder
          .addTask(GrinderTask('deploy-test', depends: ['setup', 'mode-test']));
      grinder.addTask(GrinderTask('docs', depends: ['setup']));
      grinder
          .addTask(GrinderTask('archive', depends: ['mode-notest', 'compile']));
      grinder
          .addTask(GrinderTask('release', depends: ['mode-notest', 'compile']));

      grinder.addTask(GrinderTask('clean', taskFunction: nullTaskFunction));

      grinder.start(['clean'], dontRun: true);
      expect(grinder.getBuildOrder(), orderedEquals([TaskInvocation('clean')]));
    });

    test('returns future', () {
      final buf = StringBuffer();
      final grinder = Grinder();

      grinder.addTask(GrinderTask('a1', taskFunction: ([args]) {
        final completer = Completer();
        Timer(Duration(milliseconds: 100), () {
          buf.write('a');
          completer.complete();
        });
        return completer.future;
      }));
      grinder
          .addTask(GrinderTask('a2', depends: ['a1'], taskFunction: ([args]) {
        buf.write('b');
      }));

      return grinder.start(['a2']).then((_) {
        expect(buf.toString(), 'ab');
      });
    });

    test('throw on fail', () {
      final grinder = Grinder();
      grinder.addTask(GrinderTask('i_throw', taskFunction: ([args]) {
        context.fail('boo');
      }));

      expect(grinder.start(['i_throw']), throwsA(isA<GrinderException>()));
    });
  });
}
