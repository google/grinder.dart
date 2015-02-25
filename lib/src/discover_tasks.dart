// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.get_annotated_tasks;

import 'dart:mirrors';

import '../grinder.dart';

import 'utils.dart';

/**
 * Add all [Task]-annotated tasks declared in the grinder build file.
 */
void discoverTasks(Grinder grinder, LibraryMirror lib) {
  getAnnotatedTasks(lib).forEach((annotatedTask) {
    if (annotatedTask.isDefault) {
      grinder.defaultTask = annotatedTask.task;
    } else {
      grinder.addTask(annotatedTask.task);
    }
  });
}

/// Returns tasks for all [Task]-annotated declarations in [library].
Iterable<AnnotatedTask> getAnnotatedTasks(LibraryMirror library) {
  var declarations = library.declarations.values;
  return declarations.map(getAnnotatedTask).where((task) => task != null);
}

/// Extract a task from a [Task]-annotated [declaration].
///
/// Returns `null` if [declaration] is not [Task]-annotated.
AnnotatedTask getAnnotatedTask(DeclarationMirror declaration) {
  if (declaration.isTopLevel) {
    var library = declaration.owner as LibraryMirror;
    var methodName = MirrorSystem.getName(declaration.simpleName);
    var taskAnnotations = declaration.metadata.where(
        (annotation) => annotation.reflectee is Task);

    if (taskAnnotations.isNotEmpty) {
      Task annotation = taskAnnotations.first.reflectee;
      TaskFunction taskFunction;

      if (declaration is VariableMirror ||
          (declaration is MethodMirror && declaration.isGetter)) {
        print('variable: $declaration');
        taskFunction = library.getField(declaration.simpleName).reflectee;
      } else if (declaration is MethodMirror &&
                 declaration.isRegularMethod) {
        taskFunction = (GrinderContext context) =>
            library.invoke(declaration.simpleName, [context]);
      }

      if (taskFunction == null) {
        throw new GrinderException(
            '`Task`-annotated top-level `$methodName` '
            'should be a method, variable, or getter');
      }

      var name = camelToDashes(methodName);
      var task = new GrinderTask(name,
          taskFunction: taskFunction, depends: annotation.depends,
          description: annotation.description);
      return new AnnotatedTask(task, annotation is DefaultTask);
    }
  }

  return null;
}

class AnnotatedTask {
  GrinderTask task;
  bool isDefault;

  AnnotatedTask(this.task, this.isDefault);
}
