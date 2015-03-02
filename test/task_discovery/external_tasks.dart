// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.test.task_discovery.external_tasks;

import 'package:grinder/grinder.dart';

@Task('foo description')
void shownMethod(GrinderContext context) {}

@Task()
@Depends(shownMethod)
const shownVariable = _shownVariable;
_shownVariable(GrinderContext context) {}

@Task()
void hidden(GrinderContext context) {}

@Task()
@Depends(shownMethod)
void nonHidden(GrinderContext context) {}

/// Test that non-[Task]-annotated things are not added.
nonHiddenNonTask() {}
