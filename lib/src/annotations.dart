// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

/// An annotation to mark a [GrinderTask] definition.
///
/// In your grinder entry point file, place this on top-levels which are either
/// [Function] methods or properties which return [Function]s.
///
/// Task dependencies can be defined with a co-located [Depends] annotation.
class Task {
  /// See [GrinderTask.description].
  final String? description;

  const Task([this.description]);
}

/// An annotation to define a [Task]'s dependencies.
///
/// Each listed dependency can be either a:
/// * link to a [Function] which is also annotated as a [Task]. Useful for
///   rename refactoring, finding uses, etc.
/// * [String]. Useful for referring to programmatically added tasks.
/// * [TaskInvocation]. Useful for passing args to dependencies.
class Depends {
  final dynamic dep1;
  final dynamic dep2;
  final dynamic dep3;
  final dynamic dep4;
  final dynamic dep5;
  final dynamic dep6;
  final dynamic dep7;
  final dynamic dep8;

  const Depends(this.dep1,
      [this.dep2,
      this.dep3,
      this.dep4,
      this.dep5,
      this.dep6,
      this.dep7,
      this.dep8]);

  List<dynamic> get depends => [dep1, dep2, dep3, dep4, dep5, dep6, dep7, dep8]
      .takeWhile((dep) => dep != null)
      .toList();
}

/// An annotation to define the default [GrinderTask] to run when no tasks are
/// specified on the command line.
///
/// Use this instead of [Task] when defining the default task.
class DefaultTask extends Task {
  const DefaultTask([super.description]);
}
