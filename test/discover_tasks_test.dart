// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.test.discover_tasks_test;

import 'dart:mirrors';

import 'package:grinder/src/discover_tasks.dart';
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
      var annotated = getAnnotatedTask(decl(#foo));
      expect(annotated.isDefault, isFalse);
      var task = annotated.task;
      expect(task.name, 'foo');
      expect(task.description, 'foo description');
    });

    test('variable task', () {
      var annotated = getAnnotatedTask(decl(#bar));
      var task = annotated.task;
      expect(task.name, 'bar');
      expect(task.depends, ['foo']);
    });

    test('camel case task', () {
      var annotated = getAnnotatedTask(decl(#camelCase));
      expect(annotated.task.name, 'camel-case');
    });

    test('default task', () {
      var annotated = getAnnotatedTask(decl(#def));
      expect(annotated.isDefault, isTrue);
      var task = annotated.task;
      expect(task.name, 'def');
      expect(task.depends, ['foo']);
    });

    test('should return null if not an annotated task', () {
      var annotated = getAnnotatedTask(decl(#notATask));
      expect(annotated, isNull);
    });
  });

  group('getAnnotatedTasks', () {

    test('gets annotated tasks', () {
      var tasks = getAnnotatedTasks(library);

      expect(tasks.map((annotated) => annotated.task.name), unorderedEquals([
        'foo',
        'bar',
        'camel-case',
        'def'
      ]));
    });
  });
}
