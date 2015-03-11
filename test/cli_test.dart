// Copyright 2014 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.cli_test;

import 'package:grinder/grinder.dart';
import 'package:grinder/src/cli.dart';
import 'package:unittest/unittest.dart';

bool isSetup = false;
Map ranTasks = {};

main() {
  group('cli', () {
    setUp(() {
      if (!isSetup) {
        isSetup = true;

        addTask(new GrinderTask('foo', taskFunction: _fooTask));
        addTask(new GrinderTask('bar', taskFunction: _barTask, depends: ['foo']));
      }

      _clear();
    });

    test('all ran', () {
      return handleArgs(['bar']).then((_) {
        expect(ranTasks['foo'], true);
        expect(ranTasks['bar'], true);
      });
    });
  });

  group('interation', () {
    // TODO: add some integration tests - actually execute real tasks

  });
}

void _clear() => ranTasks.clear();

_fooTask(GrinderContext context) => ranTasks['foo'] = true;

_barTask(GrinderContext context) => ranTasks['bar'] = true;
