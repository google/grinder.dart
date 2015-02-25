// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library grinder.test.annotated_tasks;

import 'package:grinder/grinder.dart';

@Task(description: 'foo description')
void foo(GrinderContext context) {}

@Task(depends: const ['foo'])
final bar = (GrinderContext context) {};

@Task()
void camelCase(GrinderContext context) {}

@DefaultTask(depends: const ['foo'])
void def(GrinderContext context) {}

/// Test that non-[Task]-annotated things are not added.
notATask() {}
