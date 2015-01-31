// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:grinder/grinder.dart';

void main([List<String> args]) {
  task('init', init);
  task('analyze', analyze, ['init']);
  task('tests', tests, ['init']);
  task('tests-web', testsWeb, ['init']);
  task('tests-build-web', testsBuildWeb, ['init']);

  startGrinder(args);
}

void init(GrinderContext context) {
  Pub.get(context);
}

void analyze(GrinderContext context) {
  Analyzer.analyzePaths(context,
      ['example/ex1.dart', 'example/ex2.dart']);
  Analyzer.analyzePaths(context,
      ['lib/grinder.dart', 'lib/grinder_files.dart', 'lib/grinder_tools.dart']);
}

void tests(GrinderContext context) {
  Tests.runCliTests(context);
}

Future testsWeb(GrinderContext context) {
  return Tests.runWebTests(context, directory: 'web', htmlFile: 'web.html');
}

Future testsBuildWeb(GrinderContext context) {
  return Pub.buildAsync(context, directories: ['web']).then((_) {
    return Tests.runWebTests(context, directory: 'build/web', htmlFile: 'web.html');
  });
}
