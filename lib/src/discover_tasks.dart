// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.discover_tasks;

import 'dart:mirrors';

import '../grinder.dart';

import 'utils.dart';

/// Add all [Task]-annotated tasks declared in the grinder build file.
void discoverTasks(Grinder grinder, LibraryMirror buildLibrary) {
  var discovery = new TaskDiscovery(buildLibrary);
  discovery.discover().forEach((annotatedTask) {
    if (annotatedTask.isDefault) {
      grinder.defaultTask = annotatedTask.task;
    } else {
      grinder.addTask(annotatedTask.task);
    }
  });
}

class TaskDiscovery {

  final LibraryMirror library;

  Map<Symbol, DeclarationMirror> get resolvedDeclarations {
    if (_resolvedDeclarations == null) {
      _resolvedDeclarations = resolveExportedDeclarations(library);
    }

    return _resolvedDeclarations;
  }
  Map<Symbol, DeclarationMirror> _resolvedDeclarations;

  TaskDiscovery(this.library);

  /// Returns tasks for all [Task]-annotated declarations in [library].
  Iterable<AnnotatedTask> discover() {
    final Map<DeclarationMirror, AnnotatedTask> cache = {};
    return resolvedDeclarations.values.map((decl) =>
        discoverDeclaration(decl, cache)).where((task) => task != null);
  }

  /// Extract a task from a [Task]-annotated [declaration].
  ///
  /// Returns `null` if [declaration] is not [Task]-annotated.
  AnnotatedTask discoverDeclaration(
      DeclarationMirror declaration,
      Map<DeclarationMirror, AnnotatedTask> cache) {
    if (cache.containsKey(declaration)) {
      return cache[declaration];
    }

    var owner = declaration.owner as LibraryMirror;
    var methodName = MirrorSystem.getName(declaration.simpleName);
    var taskAnnotations = declaration.metadata.where(
        (annotation) => annotation.reflectee is Task);

    if (taskAnnotations.isNotEmpty) {
      Task annotation = taskAnnotations.first.reflectee;
      TaskFunction taskFunction;

      if (declaration is VariableMirror ||
          (declaration is MethodMirror && declaration.isGetter)) {
        taskFunction = owner.getField(declaration.simpleName).reflectee;
      } else if (declaration is MethodMirror &&
                 declaration.isRegularMethod) {
        taskFunction = (GrinderContext context) =>
            owner.invoke(declaration.simpleName, [context]);
      }

      if (taskFunction == null) {
        throw new GrinderException(
            '`Task`-annotated top-level `$methodName` should be a task '
            'function or property which returns a task function.');
      }

      var name = camelToDashes(methodName);
      var depends = annotation.depends;

      if (depends is List) {
        depends = depends.map((dep) {
          if (dep is String) return dep;
          if (dep is TaskFunction) {
            var depMethod = (reflect(dep) as ClosureMirror).function;
            var annotatedMethodTask = discoverDeclaration(depMethod, cache);
            if (annotatedMethodTask == null) {
              var depMethodName = MirrorSystem.getName(depMethod.simpleName);
              throw new GrinderException(
                  'Task `$name` references invalid task method '
                  '`$depMethodName` as a dependency');
            }
            if (!resolvedDeclarations.values.any(
                (decl) => declarationsEqual(decl, depMethod))) {
              var depName = annotatedMethodTask.task.name;
              var depLib = MirrorSystem.getName(depMethod.owner.qualifiedName);
              throw new GrinderException(
                  'Task `$name` references dependency task `$depName` from '
                  'library `$depLib` which this build file does not export.');
            }
            return annotatedMethodTask.task.name;
          }

          throw new GrinderException(
              'Task `$name` references invalid dependency "$dep"');
        }).toList();
      }

      var task = new GrinderTask(name,
          taskFunction: taskFunction, depends: depends,
          description: annotation.description);
      var annotated = new AnnotatedTask(task, annotation is DefaultTask);

      return cache[declaration] = annotated;
    }

    return null;
  }
}

class AnnotatedTask {
  GrinderTask task;
  bool isDefault;

  AnnotatedTask(this.task, this.isDefault);
}
