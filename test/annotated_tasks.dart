
library grinder.test.annotated_tasks;

import 'package:grinder/grinder.dart';

@Task(description: 'foo description')
void foo(GrinderContext context) {}

@Task(depends: const ['foo'])
final bar = (GrinderContext context) {};

@Task()
void camelCase(GrinderContext context) {}

@Task(name: 'renamed')
void name(GrinderContext context) {}
