// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'package:grinder/grinder.dart';

void main([List<String> args]) {
  task('init', init);
  task('analyze', analyze, ['init']);
  task('tests', tests, ['init']);

  startGrinder(args);
}

void init(GrinderContext context) {
  Pub.get(context);
}

void analyze(GrinderContext context) {
  Analyzer.analyzePaths(context,
      ['example/ex1.dart', 'example/ex2.dart']);
  Analyzer.analyzePaths(context,
      ['lib/grinder.dart', 'lib/grinder_files.dart', 'lib/grinder_utils.dart']);
}

void tests(GrinderContext context) {
  runDartScript(context, "test/all.dart");
}
