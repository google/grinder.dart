// Copyright 2014 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.integration_test;

import 'package:grinder/grinder.dart';
import 'package:grinder/src/cli.dart';
import 'package:test/test.dart';

import 'src/_common.dart';

Map ranTasks = {};

main() {
  group('integration', () {
    bool isSetup = false;

    setUp(() {
      if (!isSetup) {
        isSetup = true;
        addTask(new GrinderTask('foo', taskFunction: _fooTask));
        addTask(
            new GrinderTask('bar', taskFunction: _barTask, depends: ['foo']));
      }

      _clear();
    });

    grinderTest('all ran', () {
      return handleArgs(['bar']);
    }, (ctx) {
      expect(ctx.isFailed, false);
      expect(ranTasks['foo'], true);
      expect(ranTasks['bar'], true);
    });
  });
}

void _clear() => ranTasks.clear();

_fooTask() {
  ranTasks['foo'] = true;
  log('ran _fooTask');
}

_barTask(GrinderContext context) {
  ranTasks['bar'] = true;
  log('ran _barTask\n${context}');
}
