// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.discover_tasks;

import 'dart:mirrors';

import '../grinder.dart';
import 'utils.dart';

/// Add all [Task]-annotated tasks declared in the grinder build file.
void discoverTasks(Grinder grinder, LibraryMirror buildLibrary) {
  var discovery = TaskDiscovery(buildLibrary);
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

  late final Map<Symbol, DeclarationMirror> resolvedDeclarations =
      resolveExportedDeclarations(library);

  TaskDiscovery(this.library);

  /// Returns tasks for all [Task]-annotated declarations in [library].
  Iterable<AnnotatedTask> discover() {
    final cache = <DeclarationMirror, AnnotatedTask>{};
    return resolvedDeclarations.values
        .map((decl) => discoverDeclaration(decl, cache))
        .nonNulls;
  }

  /// Extract a task from a [Task]-annotated [decl].
  ///
  /// Returns `null` if [decl] is not [Task]-annotated.
  AnnotatedTask? discoverDeclaration(
      DeclarationMirror decl, Map<DeclarationMirror, AnnotatedTask> cache) {
    if (cache.containsKey(decl)) {
      return cache[decl];
    }

    var owner = decl.owner;
    if (owner is! LibraryMirror) {
      throw ArgumentError.value(decl, 'decl',
          'discoverDeclaration() may only be called on a top-level method.');
    }

    var methodName = MirrorSystem.getName(decl.simpleName);
    var annotation = getFirstMatchingAnnotation<Task>(decl);
    var dependsAnnotation = getFirstMatchingAnnotation<Depends>(decl);

    if (annotation == null && dependsAnnotation != null) {
      throw GrinderException(
          'Top-level `$methodName` is annotated with `Depends` but not '
          '`Task`');
    }

    if (annotation != null) {
      Function? taskFunction;

      if (decl is VariableMirror || (decl is MethodMirror && decl.isGetter)) {
        taskFunction = owner.getField(decl.simpleName).reflectee;
      } else if (decl is MethodMirror && decl.isRegularMethod) {
        if (decl.parameters.isNotEmpty &&
            !decl.parameters.first.isOptional &&
            !decl.parameters.first.isNamed) {
          taskFunction =
              () => owner.invoke(decl.simpleName, [context]).reflectee;
        } else {
          taskFunction = () => owner.invoke(decl.simpleName, []).reflectee;
        }
      }

      if (taskFunction == null) {
        throw GrinderException(
            '`Task`-annotated top-level `$methodName` should be a task '
            'function or property which returns a task function.');
      }

      var name = camelToDashes(methodName);

      var depends = [];
      if (dependsAnnotation != null) {
        depends = dependsAnnotation.depends.map((dep) {
          if (dep is TaskInvocation) return dep;
          if (dep is String) return TaskInvocation(dep);
          if (dep is Function) {
            var depMethod = (reflect(dep) as ClosureMirror).function;
            var annotatedMethodTask = discoverDeclaration(depMethod, cache);
            if (annotatedMethodTask == null) {
              var depMethodName = MirrorSystem.getName(depMethod.simpleName);
              throw GrinderException(
                  'Task `$name` references invalid task method '
                  '`$depMethodName` as a dependency');
            }
            if (!resolvedDeclarations.values.any((decl) => decl == depMethod)) {
              var depName = annotatedMethodTask.task.name;
              var depLib = MirrorSystem.getName(depMethod.owner!.qualifiedName);
              throw GrinderException(
                  'Task `$name` references dependency task `$depName` from '
                  'library `$depLib` which this build file does not export.');
            }
            return TaskInvocation(annotatedMethodTask.task.name);
          }

          throw GrinderException(
              'Task `$name` references invalid dependency "$dep"');
        }).toList();
      }

      var task = GrinderTask(name,
          taskFunction: taskFunction,
          depends: depends,
          description: annotation.description);
      var annotated = AnnotatedTask(task, annotation is DefaultTask);

      return cache[decl] = annotated;
    }

    return null;
  }
}

class AnnotatedTask {
  GrinderTask task;
  bool isDefault;

  AnnotatedTask(this.task, this.isDefault);
}
