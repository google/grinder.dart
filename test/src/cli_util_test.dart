// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.cli_test;

import 'package:grinder/src/cli_util.dart';
import 'package:grinder/src/grinder.dart';
import 'package:grinder/src/grinder_task.dart';
import 'package:test/test.dart';

import '_common.dart';

// TODO: test('throws on invalid task name', () {

main() {
  group('cli_util', () {
    group('ArgParser', () {
      // TODO: test ArgParser
    });

    group('getTaskHelp', () {
      test('with tasks', () {
        var grinder = new Grinder();
        grinder.addTask(new GrinderTask('a',
            description: '1', taskFunction: nullTaskFunction));
        grinder.addTask(new GrinderTask('b',
            description: '2', taskFunction: nullTaskFunction));
        grinder.addTask(
            new GrinderTask('ab', description: '', depends: ['a', 'b']));
        grinder.addTask(
            new GrinderTask('abc', description: '123', depends: ['ab']));

        var help = getTaskHelp(grinder, useColor: false);
        expect(help.trim(), '''a                    1
  b                    2
  ab                   (depends on: a b)
  abc                  123
                       (depends on: ab)''');
      });

      test('without tasks', () {
        var grinder = new Grinder();

        var help = getTaskHelp(grinder, useColor: false);
        expect(help.trim(), 'No tasks defined.');
      });
    });
  });
}
