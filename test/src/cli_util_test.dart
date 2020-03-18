// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.cli_test;

import 'package:grinder/src/cli.dart';
import 'package:grinder/src/cli_util.dart';
import 'package:grinder/src/grinder.dart';
import 'package:grinder/src/grinder_task.dart';
import 'package:test/test.dart';

import '_common.dart';

void main() {
  group('cli_util', () {
    group('ArgParser', () {
      test('flags and tasks', () {
        final parser = ArgParser('foo', 'foo description', () => '');
        parser.addFlag('help', abbr: 'h');
        parser.addFlag('foo');
        parser.addFlag('bar');

        final results =
            parser.parse(['-h', '--foo', 'task1', '--foo', 'task2']);

        expect(results.getFlag('help'), true);
        expect(results.getFlag('foo'), true);
        expect(results.getFlag('bar'), false);

        expect(results.taskInvocations, hasLength(2));

        var task = results.taskInvocations.first;
        expect(task.name, 'task1');
        expect(task.arguments.getFlag('foo'), true);

        task = results.taskInvocations[1];
        expect(task.name, 'task2');
        expect(task.arguments.arguments, isEmpty);
      });
    });

    group('getTaskHelp', () {
      test('with tasks', () {
        var grinder = Grinder();
        grinder.addTask(
            GrinderTask('a', description: '1', taskFunction: nullTaskFunction));
        grinder.addTask(
            GrinderTask('b', description: '2', taskFunction: nullTaskFunction));
        grinder
            .addTask(GrinderTask('ab', description: '', depends: ['a', 'b']));
        grinder
            .addTask(GrinderTask('abc', description: '123', depends: ['ab']));

        var help = getTaskHelp(grinder, useColor: false);
        expect(help.trim(), '''a                    1
  b                    2
  ab                   (depends on: a b)
  abc                  123
                       (depends on: ab)''');
      });

      test('without tasks', () {
        var grinder = Grinder();

        var help = getTaskHelp(grinder, useColor: false);
        expect(help.trim(), 'No tasks defined.');
      });
    });
  });
}
