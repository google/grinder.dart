// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

// ignore_for_file: prefer_void_to_null

library grinder.test.task_discovery.bad_tasks;

import 'package:grinder/grinder.dart';

import 'external_tasks.dart';

export 'external_tasks.dart' show shownVariable;

@Task()
const dynamic nullTask = null;

@Task()
Null get nullReturningGetter => null;

@Task()
class Class {}

@Task()
@Depends(shownMethod)
void dependsNonExported(GrinderContext context) {}

@Task()
@Depends(shownVariable)
void recursivelyDependsNonExported(GrinderContext context) {}

@Task()
@Depends(nonTask)
void dependsNonTask(GrinderContext context) {}

@Depends(hidden)
void dependsWithoutTask() {}

/// Test that non-[Task]-annotated things are not added.
void nonTask() {}
