// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'package:grinder/grinder.dart';

void main([List<String> args]) {
  task('init', run: init);
  task('analyze', run: analyze, depends: ['init']);
  task('tests', run: tests, depends: ['init']);

  startGrinder(args);
}

void init(GrinderContext context) {
  PubTools pub = new PubTools();
  pub.get(context);
}

void analyze(GrinderContext context) {
  runSdkBinary(context, 'dartanalyzer', arguments: ['lib/grinder.dart']);
  runSdkBinary(context, 'dartanalyzer', arguments: ['lib/grinder_files.dart']);
  runSdkBinary(context, 'dartanalyzer', arguments: ['lib/grinder_utils.dart']);
  runSdkBinary(context, 'dartanalyzer', arguments: ['example/ex1.dart']);
}

void tests(GrinderContext context) {
  runDartScript(context, "test/all.dart");
}
