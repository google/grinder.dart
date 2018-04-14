// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.test.task_discovery.discover_tasks_test;

import 'dart:mirrors';

import 'package:grinder/grinder.dart';
import 'package:grinder/src/discover_tasks.dart';
import 'package:test/test.dart';

import '_common.dart';
import 'task_discovery/bad_tasks.dart' as bad;
import 'task_discovery/external_tasks.dart' as external_tasks;
import 'task_discovery/good_tasks.dart' as good;

main() {
  // Libs which contains annotated tasks (imported above).
  LibraryMirror goodLib;
  LibraryMirror badLib;
  LibraryMirror externalLib;
  externalLib;

  // Dummy calls to avoid "unused import" warnings.
  good.variable;
  bad.dependsNonExported;
  external_tasks.shownVariable;
  externalLib;

  TaskDiscovery discoveryGood;
  TaskDiscovery discoveryBad;
  setUp(() {
    LibraryMirror getLib(Symbol name) => currentMirrorSystem()
        .libraries
        .values
        .singleWhere((lib) => lib.qualifiedName == name);

    goodLib = getLib(#grinder.test.task_discovery.good_tasks);
    badLib = getLib(#grinder.test.task_discovery.bad_tasks);
    externalLib = getLib(#grinder.test.task_discovery.external_tasks);
    discoveryGood = new TaskDiscovery(goodLib);
    discoveryBad = new TaskDiscovery(badLib);
  });

  group('discoverDeclaration', () {
    test('should set cache', () {
      Map<DeclarationMirror, AnnotatedTask> cache = {};
      DeclarationMirror methodDecl = goodLib.declarations[#method];
      var annotated = discoveryGood.discoverDeclaration(methodDecl, cache);
      expect(annotated.isDefault, isFalse);
      expect(cache, {methodDecl: annotated});
    });

    test('should get from cache', () {
      var methodDecl = goodLib.declarations[#method];
      var annotated = new AnnotatedTask(
          new GrinderTask('method', taskFunction: nullTaskFunction), false);
      var cache = {methodDecl: annotated};
      var result = discoveryGood.discoverDeclaration(methodDecl, cache);
      expect(result, same(annotated));
    });

    test('should discover task from regular method', () {
      var annotated =
          discoveryGood.discoverDeclaration(goodLib.declarations[#method], {});
      expect(annotated.isDefault, isFalse);
      var task = annotated.task;
      expect(task.name, 'method');
      expect(task.description, 'method description');
    });

    test('should discover task from variable', () {
      var annotated = discoveryGood
          .discoverDeclaration(goodLib.declarations[#variable], {});
      var task = annotated.task;
      expect(task.name, 'variable');
      expect(task.depends, [new TaskInvocation('method')]);
    });

    test('should discover task from getter', () {
      var annotated =
          discoveryGood.discoverDeclaration(goodLib.declarations[#getter], {});
      var task = annotated.task;
      expect(task.name, 'getter');
      expect(task.depends, [new TaskInvocation('method')]);
    });

    test('should dasherize camel case task method', () {
      var annotated = discoveryGood
          .discoverDeclaration(goodLib.declarations[#camelCase], {});
      expect(annotated.task.name, 'camel-case');
    });

    test('should discover a default task', () {
      var annotated =
          discoveryGood.discoverDeclaration(goodLib.declarations[#def], {});
      expect(annotated.isDefault, isTrue);
      var task = annotated.task;
      expect(task.name, 'def');
      expect(task.depends, [new TaskInvocation('method')]);
    });

    test('should return null for non-Task-annotated declarations', () {
      var annotated =
          discoveryGood.discoverDeclaration(goodLib.declarations[#nonTask], {});
      expect(annotated, isNull);
    });

    test('should throw when variable task is null', () {
      f() =>
          discoveryBad.discoverDeclaration(badLib.declarations[#nullTask], {});
      expect(f, throwsA(new isInstanceOf<GrinderException>()));
    });

    test('should throw when task getter returns null', () {
      f() => discoveryBad
          .discoverDeclaration(badLib.declarations[#nullReturningGetter], {});
      expect(f, throwsA(new isInstanceOf<GrinderException>()));
    });

    test('should throw when task is wront type of declaration', () {
      f() => discoveryBad.discoverDeclaration(badLib.declarations[#Class], {});
      expect(f, throwsA(new isInstanceOf<GrinderException>()));
    });

    test('should throw when depending on non-exported task', () {
      f() => discoveryBad
          .discoverDeclaration(badLib.declarations[#dependsNonExported], {});
      expect(f, throwsA(new isInstanceOf<GrinderException>()));
    });

    test('should throw when recursively depending on non-exported task', () {
      f() => discoveryBad.discoverDeclaration(
          badLib.declarations[#recursivelyDependsNonExported], {});
      expect(f, throwsA(new isInstanceOf<GrinderException>()));
    });

    test('should throw when depending on invalid task', () {
      f() => discoveryBad
          .discoverDeclaration(badLib.declarations[#dependsNonTask], {});
      expect(f, throwsA(new isInstanceOf<GrinderException>()));
    });

    test('should throw when annotated with Depends but not Task', () {
      f() => discoveryBad
          .discoverDeclaration(badLib.declarations[#dependsWithoutTask], {});
      expect(f, throwsA(new isInstanceOf<GrinderException>()));
    });
  });

  group('execute returns value', () {
    grinderTest('task from method', () {}, (MockGrinderContext ctx) {
      var annotated =
          discoveryGood.discoverDeclaration(goodLib.declarations[#method], {});
      expect(annotated.task.execute(ctx, null), 'someValue');
    });

    grinderTest('task from method no-context', () {}, (MockGrinderContext ctx) {
      var annotated = discoveryGood
          .discoverDeclaration(goodLib.declarations[#noContext], {});
      expect(annotated.task.execute(ctx, null), 'someValue');
    });

    grinderTest('task from variable', () {}, (MockGrinderContext ctx) {
      var annotated = discoveryGood
          .discoverDeclaration(goodLib.declarations[#variable], {});
      expect(annotated.task.execute(ctx, null), 'someValue');
    });

    grinderTest('task from getter', () {}, (MockGrinderContext ctx) {
      var annotated =
          discoveryGood.discoverDeclaration(goodLib.declarations[#getter], {});
      expect(annotated.task.execute(ctx, null), 'someValue');
    });
  });

  group('discover', () {
    test('should discover all exported tasks', () {
      var tasks = discoveryGood.discover();

      expect(
          tasks.map((annotated) => annotated.task.name),
          unorderedEquals([
            'method',
            'variable',
            'getter',
            'camel-case',
            'def',
            'shown-method',
            'shown-variable',
            'non-hidden',
            'no-context'
          ]));
    });
  });
}
