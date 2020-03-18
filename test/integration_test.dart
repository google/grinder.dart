// Copyright 2014 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.integration_test;

import 'package:grinder/grinder.dart';
import 'package:grinder/src/cli.dart';
import 'package:test/test.dart';

import 'src/_common.dart';

Map ranTasks = {};

void main() {
  group('integration', () {
    var isSetup = false;

    setUp(() {
      if (!isSetup) {
        isSetup = true;
        addTask(GrinderTask('foo', taskFunction: _fooTask));
        addTask(GrinderTask('bar', taskFunction: _barTask, depends: ['foo']));
        addTask(GrinderTask('baz', taskFunction: _bazTask));
      }

      _clear();
    });

    grinderTest('run dependent tasks',
        () => runTasks(['bar', '--flag', '--option=123', 'baz']), (ctx) {
      expect(ctx.isFailed, false);

      // run dependent tasks
      expect(ranTasks['foo'], true);
      expect(ranTasks['bar'], true);

      // pass args
      expect(ranTasks['flag'], true);
      expect(ranTasks['option'], '123');

      // old form
      expect(ranTasks['baz'], true);
    });
  });
}

void _clear() => ranTasks.clear();

void _fooTask() {
  ranTasks['foo'] = true;

  log('ran _fooTask');
}

void _barTask(TaskArgs args) {
  ranTasks['bar'] = true;
  ranTasks['flag'] = args.getFlag('flag');
  ranTasks['option'] = args.getOption('option');

  log('ran _barTask\n${context}');
}

// old form
void _bazTask(GrinderContext c) {
  ranTasks['baz'] = true;

  log('baz _fooTask');
}
