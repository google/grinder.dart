// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:grinder/grinder.dart';

void main([List<String> args]) {
  addAnnotatedTasks();
  startGrinder(args);
}

@Task()
void init(GrinderContext context) {
  Pub.get(context);
}

@Task(depends: const ['init'])
void analyze(GrinderContext context) {
  Analyzer.analyzePaths(context,
      ['example/ex1.dart', 'example/ex2.dart']);
  Analyzer.analyzePaths(context,
      ['lib/grinder.dart', 'lib/grinder_files.dart', 'lib/grinder_tools.dart']);
}

@Task(depends: const ['init'])
void tests(GrinderContext context) {
  Tests.runCliTests(context);
}

@Task(depends: const ['init'])
Future testsWeb(GrinderContext context) {
  return Tests.runWebTests(context, directory: 'web', htmlFile: 'web.html');
}

@Task(depends: const ['init'])
Future testsBuildWeb(GrinderContext context) {
  return Pub.buildAsync(context, directories: ['web']).then((_) {
    return Tests.runWebTests(context, directory: 'build/web', htmlFile: 'web.html');
  });
}
