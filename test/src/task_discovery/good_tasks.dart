// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

// ignore_for_file: prefer_function_declarations_over_variables

library grinder.test.task_discovery.good_tasks;

import 'package:grinder/grinder.dart';

export 'external_tasks.dart' show shownMethod, shownVariable;
export 'external_tasks.dart' hide shownMethod, shownVariable, hidden;

@Task('method description')
String method(GrinderContext context) => 'someValue';

@Task()
@Depends(method)
final variable = (GrinderContext context) => 'someValue';

@Task()
@Depends('method')
String Function(GrinderContext) get getter =>
    (GrinderContext context) => 'someValue';

@Task()
void camelCase(GrinderContext context) {}

@Task()
String noContext() => 'someValue';

@DefaultTask()
@Depends(method)
void def(GrinderContext context) {}

/// Test that non-[Task]-annotated things are not added.
void nonTask() {}
