// Copyright 2014 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'package:grinder/grinder.dart';
import 'package:grinder/src/cli.dart';
import 'package:test/test.dart';

import 'src/common.dart';

Map<String, Object?> ranTasks = {};

void main() {
  group('integration', () {
    var isSetup = false;

    setUp(() {
      if (!isSetup) {
        isSetup = true;
        addTask(GrinderTask('foo', taskFunction: _fooTask));
        addTask(GrinderTask('bar', taskFunction: _barTask, depends: ['foo']));
      }

      _clear();
    });

    grinderTest('run dependent tasks',
        () => runTasks(['bar', '--flag', '--option=123']), (ctx) {
      expect(ctx.isFailed, false);

      // run dependent tasks
      expect(ranTasks['foo'], true);
      expect(ranTasks['bar'], true);

      // pass args
      expect(ranTasks['flag'], true);
      expect(ranTasks['option'], '123');
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

  log('ran _barTask\n$context');
}
