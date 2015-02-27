// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.test.task_discovery.bad_tasks;

import 'package:grinder/grinder.dart';

import 'external_tasks.dart';

export 'external_tasks.dart' show shownVariable;

@Task()
const nullTask = null;

@Task()
get nullReturningGetter => null;

@Task()
class Class {}

@Task(depends: const [shownMethod])
dependsNonExported(GrinderContext context) {}

@Task(depends: const [shownVariable])
recursivelyDependsNonExported(GrinderContext context) {}

@Task(depends: const [nonTask])
dependsNonTask(GrinderContext context) {}

/// Test that non-[Task]-annotated things are not added.
nonTask() {}
