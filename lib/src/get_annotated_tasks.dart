// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.src.add_annotated_tasks;

import 'dart:mirrors';

import '../grinder.dart';

import 'utils.dart';

/// Returns tasks for all [Task]-annotated declarations in [library].
Iterable<GrinderTask> getAnnotatedTasks(LibraryMirror library) {
  var declarations = library.declarations.values;
  return declarations.map(getAnnotatedTask).where((task) => task != null);
}

/// Extract a task from a [Task]-annotated [declaration].
///
/// Returns `null` if [declaration] is not [Task]-annotated.
GrinderTask getAnnotatedTask(DeclarationMirror declaration) {
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

      var name = annotation.name != null
          ? annotation.name : camelToDashes(methodName);
      return new GrinderTask(name,
          taskFunction: taskFunction, depends: annotation.depends,
          description: annotation.description);
    }
  }
  return null;
}
