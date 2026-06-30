// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

// ignore_for_file: prefer_function_declarations_over_variables

import 'package:grinder/grinder.dart';

export 'external_tasks.dart' show shownMethod, shownVariable;
export 'external_tasks.dart' hide shownMethod, shownVariable, hidden;

@Task('method description')
String method() => 'someValue';

@Task()
@Depends(method)
final variable = () => 'someValue';

@Task()
@Depends('method')
String Function() get getter => () => 'someValue';

@Task()
void camelCase() {}

@Task()
String noContext() => 'someValue';

@DefaultTask()
@Depends(method)
void def() {}

/// Test that non-[Task]-annotated things are not added.
void nonTask() {}
