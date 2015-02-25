// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.test.get_annotated_tasks_test;

import 'dart:mirrors';

import 'package:grinder/src/get_annotated_tasks.dart';
import 'package:unittest/unittest.dart';

import 'annotated_tasks.dart';

main() {

  // The lib which contains the annotated tasks, imported above.
  var annotatedTasksLib = #grinder.test.annotated_tasks;

  // Dummy call to avoid "unused import" warning.
  // TODO: Remove if it becomes unnecessary:
  //     https://github.com/dart-lang/reflectable/issues/2
  bar;

  LibraryMirror library;
  setUp(() {
    library = currentMirrorSystem().libraries.values.singleWhere(
        (lib) => lib.qualifiedName == annotatedTasksLib);
  });

  DeclarationMirror decl(Symbol symbol) => library.declarations[symbol];

  group('getAnnotatedTask', () {

    test('regular method task', () {
      var task = getAnnotatedTask(decl(#foo));
      expect(task.name, 'foo');
      expect(task.description, 'foo description');
    });

    test('variable task', () {
      var task = getAnnotatedTask(decl(#bar));
      expect(task.name, 'bar');
      expect(task.depends, ['foo']);
    });

    test('camel case task', () {
      var task = getAnnotatedTask(decl(#camelCase));
      expect(task.name, 'camel-case');
    });

    test('renamed task', () {
      var task = getAnnotatedTask(decl(#name));
      expect(task.name, 'renamed');
    });
  });

  group('getAnnotatedTasks', () {

    test('gets annotated tasks', () {
      var tasks = getAnnotatedTasks(library);

      expect(tasks.map((task) => task.name), unorderedEquals([
        'foo',
        'bar',
        'camel-case',
        'renamed'
      ]));
    });
  });
}
