// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.test.task_discovery.good_tasks;

import 'package:grinder/grinder.dart';

export 'external_tasks.dart' show shownMethod, shownVariable;
export 'external_tasks.dart' hide shownMethod, shownVariable, hidden;

@Task('method description')
void method(GrinderContext context) {}

@Task()
@Depends(method)
final variable = (GrinderContext context) {};

@Task()
@Depends('method')
get getter => (GrinderContext context) {};

@Task()
void camelCase(GrinderContext context) {}

@DefaultTask()
@Depends(method)
void def(GrinderContext context) {}

/// Test that non-[Task]-annotated things are not added.
nonTask() {}
